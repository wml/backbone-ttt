require 'game'

module AI
  module_function
  def _take_first_available board
    0.upto(board.count - 1) do |row|
      0.upto(board[row].count - 1) do |col|
        if Game.States[:Open] == board[row][col]
          board[row][col] = Game.States[:Opponent]
          return board
        end
      end
    end
  end

  class FirstAvailable 
    def self.move board
      return AI._take_first_available(board)
    end
  end

  class Minimax
    def self.move board
      return self.algo(true, board, true, { }, 1, -100, 100)
    end

    def self.algo myturn, board, root, solutions, depth, alpha, beta
      boardkey = board.to_s
      if solutions.include? boardkey
        return solutions[boardkey]
      end

      score = (10 - depth) * self.score(board)
      children = self.children(myturn, board)

      if 0 == children.count or 0 != score
        return score
      end

      bestscore = nil
      bestmove = nil

      children.each do |child|
        score = self.algo(
          (not myturn), child, false, solutions, 1 + depth, alpha, beta
        )

        if myturn
          alpha = [alpha, score].max
          if nil == bestscore or score > bestscore
            bestscore = score
            bestmove = child
          end
          if beta <= alpha
            break
          end
        else
          beta = [beta, score].min
          if nil == bestscore or score < bestscore
            bestscore = score
            bestmove = child
          end
          if beta <= alpha
            break
          end
        end
      end

      if root
        return bestmove
      else
        solutions[boardkey] = bestscore
        return bestscore
      end
    end

    def self.children myturn, board
      results = []
      for row in 0..2
        for col in 0..2
          if board[row][col] == Game.States[:Open]
            results += [self.get_child(board, myturn, row, col)]
          end
        end
      end
      return results
    end

    def self.get_child board, myturn, row, col
      result = [[],[],[]]

      for r in 0..2
        for c in 0..2
          result[r][c] = board[r][c]
        end
      end

      result[row][col] = (myturn ? Game.States[:Opponent] : Game.States[:Human])
      return result
    end

    def self.score board
      scores = {
        Game.States[:Opponent] => 1,
        Game.States[:Human] => -1,
        Game.States[:Open] => 0,
        Game.States[:Tie] => 0,
      }

      return scores[Game.winner(board)]
    end
  end

  class Heuristic
    class LineState
      attr_reader :available
      attr_reader :human
      attr_reader :opponent

      def initialize move_impl
        @available = []
        @human = []
        @opponent = []
        @move_impl = move_impl
      end

      def update who, idx
        case who
        when Game.States[:Open] then @available.push(idx)
        when Game.States[:Human] then @human.push(idx)
        else @opponent.push(idx)
        end
      end

      def move idx, who
        @move_impl.call idx, who
      end

      def clear idx
        @move_impl.call idx, Game.States[:Open]
      end
    end

    def self.move board
      rules = [
        :winning_move,
        :block_win,
        :fork,
        :block_fork,
        :center,
        :opposite_corner,
        :any_corner,
        :first_available
      ]
      
      rules.each do |rule|
        if Heuristic.send rule, board
          return board
        end
      end
    end
   
    def self.winning_move board
      return self._eval_state board, lambda { |linestate|
        if linestate.opponent.count == 2 and linestate.available.count > 0
          linestate.move linestate.available[0], Game.States[:Opponent]
          return true
        end
        return false
      }
    end

    def self.block_win board
      return self._eval_state board, lambda { |linestate|
        if linestate.human.count == 2 and linestate.available.count > 0
          linestate.move linestate.available[0], Game.States[:Opponent]
          return true
        end
        return false
      }
    end

    def self.fork board
      result = self._first_fork board, Game.States[:Opponent]
      if result
        board[result[0]][result[1]] = Game.States[:Opponent]
      end
      return nil != result
    end

    def self.block_fork board
      human_fork_location = self._first_fork board, Game.States[:Human]
      if nil == human_fork_location
        return false
      end

      moved = self._eval_state board, lambda { |linestate|
        if linestate.opponent.count == 1 and linestate.available.count == 2
          for i in 0..1
            moveidx = linestate.available[i]
            blockidx = linestate.available[(1 + i) % 2]

            linestate.move moveidx, Game.States[:Opponent]
            linestate.move blockidx, Game.States[:Human]

            human_win_opportunities = 0
            self._eval_state board, lambda { |lsinner|
              if lsinner.available.count == 1 and lsinner.human.count == 2
                human_win_opportunities += 1
              end
              return false
            }

            linestate.clear blockidx

            if human_win_opportunities < 2
              return true
            end

            linestate.clear moveidx
          end
        end
        return false
      }
      
      if not moved
        board[human_fork_location[0]][human_fork_location[1]] = Game.States[:Opponent]
      end

      return true
    end

    def self._first_fork board, who
      for row in 0..2
        for col in 0..2
          if Game.States[:Open] == board[row][col]
            board[row][col] = who
            opportunities = 0

            self._eval_state(
              board, lambda { |linestate|
                if ((who == Game.States[:Opponent] and linestate.opponent.count == 2) \
                    or (who == Game.States[:Human] and linestate.human.count == 2)) \
                    and linestate.available.count > 0
                  opportunities += 1
                end
                return false
              }
            )
    
            if opportunities >= 2
              board[row][col] = Game.States[:Open]
              return [row, col]
            end

            board[row][col] = Game.States[:Open]
          end
        end
      end
            
      return nil
    end

    def self.center board
      if board[1][1] == Game.States[:Open]
        board[1][1] = Game.States[:Opponent]
        return true
      end
      return false
    end

    def self.opposite_corner board
      if board[0][0] == Game.States[:Human] and board[2][2] == Game.States[:Open]
        board[2][2] = Game.States[:Opponent]
      elsif board[0][2] == Game.States[:Human] and board[2][0] == Game.States[:Open]
        board[2][0] = Game.States[:Opponent]
      elsif board[2][0] == Game.States[:Human] and board[0][2] == Game.States[:Open]
        board[0][2] = Game.States[:Opponent]
      elsif board[2][2] == Game.States[:Human] and board[0][0] == Game.States[:Open]
        board[0][0] = Game.States[:Opponent]
      else
        return false
      end

      return true
    end

    def self.any_corner board
      if board[2][2] == Game.States[:Open]
        board[2][2] = Game.States[:Opponent]
      elsif board[2][0] == Game.States[:Open]
        board[2][0] = Game.States[:Opponent]
      elsif board[0][2] == Game.States[:Open]
        board[0][2] = Game.States[:Opponent]
      elsif board[0][0] == Game.States[:Open]
        board[0][0] = Game.States[:Opponent]
      else 
        return false
      end

      return true
    end

    def self.first_available board
      AI._take_first_available board
      return true
    end

    def self._eval_state board, report_state
      if self._eval_rows board, report_state
        return true
      elsif self._eval_cols board, report_state
        return true
      elsif self._eval_ulbr board, report_state
        return true
      else
        return self._eval_blur board, report_state
      end
    end

    def self._eval_rows board, report_state
      0.upto(board.count - 1) do |row|
        linestate = LineState.new(
          lambda {|idx, who| board[row][idx] = who }
        )

        0.upto(board[row].count - 1) do |col|
          linestate.update board[row][col], col
        end

        if report_state.call(linestate)
          return true
        end
      end

      return false
    end
    
    def self._eval_cols board, report_state
      0.upto(board.count - 1) do |col|
        linestate = LineState.new(
          lambda {|idx, who| board[idx][col] = who}
        )

        0.upto(board[col].count - 1) do |row|
          linestate.update board[row][col], row
        end

        if report_state.call(linestate)
          return true
        end
      end

      return false
    end
  
    def self._eval_ulbr board, report_state
      linestate = LineState.new(
        lambda {|idx, who| board[idx][idx] = who}
      )

      0.upto(2) do |rowcol|
        linestate.update board[rowcol][rowcol], rowcol
      end

      return report_state.call(linestate)
    end

    def self._eval_blur board, report_state
      linestate = LineState.new(
        lambda {|idx, who| board[2 - idx][idx] = who}
      )

      0.upto(2) do |rowcol|
        linestate.update board[2 - rowcol][rowcol], rowcol
      end

      return report_state.call(linestate)
    end
  end

  class Sloppy
    def self.move board
      if 0 == rand(10)
        return self.random_move(board)
      end
      return Minimax.move board
    end

    def self.random_move board
      moves = []

      for row in 0..2
        for col in 0..2
          if board[row][col] == Game.States[:Open]
            moves.append([row, col])
          end
        end
      end

      move = moves[rand(moves.count)]
      board[move[0]][move[1]] = Game.States[:Opponent]

      return board
    end
  end
end
