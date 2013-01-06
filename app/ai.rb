require 'json'
require 'game'

module AI
  module_function
  def _take_first_available state
    0.upto(state.count - 1) do |row|
      0.upto(state[row].count - 1) do |col|
        if Game.States[:Open] == state[row][col]
          state[row][col] = Game.States[:Opponent]
          return state
        end
      end
    end
  end

  class FirstAvailable 
    def self.move state
      return JSON.dump(AI._take_first_available(JSON.parse(state)))
    end
  end

  class Minimax
    def self.move state
      state = JSON.parse(state)
      return JSON.dump(self.algo(true, state, true, { }, 1, -100, 100))
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

    def self.move state
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
      
      state = JSON.parse(state)

      rules.each do |rule|
        if Heuristic.send rule, state
          return JSON.dump(state)
        end
      end
    end
   
    def self.winning_move state
      return self._eval_state state, lambda { |linestate|
        if linestate.opponent.count == 2 and linestate.available.count > 0
          linestate.move linestate.available[0], Game.States[:Opponent]
          return true
        end
        return false
      }
    end

    def self.block_win state
      return self._eval_state state, lambda { |linestate|
        if linestate.human.count == 2 and linestate.available.count > 0
          linestate.move linestate.available[0], Game.States[:Opponent]
          return true
        end
        return false
      }
    end

    def self.fork state
      result = self._first_fork state, Game.States[:Opponent]
      if result
        state[result[0]][result[1]] = Game.States[:Opponent]
      end
      return nil != result
    end

    def self.block_fork state
      human_fork_location = self._first_fork state, Game.States[:Human]
      if nil == human_fork_location
        return false
      end

      moved = self._eval_state state, lambda { |linestate|
        if linestate.opponent.count == 1 and linestate.available.count == 2
          for i in 0..1
            moveidx = linestate.available[i]
            blockidx = linestate.available[(1 + i) % 2]

            linestate.move moveidx, Game.States[:Opponent]
            linestate.move blockidx, Game.States[:Human]

            human_win_opportunities = 0
            self._eval_state state, lambda { |lsinner|
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
        state[human_fork_location[0]][human_fork_location[1]] = Game.States[:Opponent]
      end

      return true
    end

    def self._first_fork state, who
      for row in 0..2
        for col in 0..2
          if Game.States[:Open] == state[row][col]
            state[row][col] = who
            opportunities = 0

            self._eval_state(
              state, lambda { |linestate|
                if ((who == Game.States[:Opponent] and linestate.opponent.count == 2) \
                    or (who == Game.States[:Human] and linestate.human.count == 2)) \
                    and linestate.available.count > 0
                  opportunities += 1
                end
                return false
              }
            )
    
            if opportunities >= 2
              state[row][col] = Game.States[:Open]
              return [row, col]
            end

            state[row][col] = Game.States[:Open]
          end
        end
      end
            
      return nil
    end

    def self.center state
      if state[1][1] == Game.States[:Open]
        state[1][1] = Game.States[:Opponent]
        return true
      end
      return false
    end

    def self.opposite_corner state
      if state[0][0] == Game.States[:Human] and state[2][2] == Game.States[:Open]
        state[2][2] = Game.States[:Opponent]
      elsif state[0][2] == Game.States[:Human] and state[2][0] == Game.States[:Open]
        state[2][0] = Game.States[:Opponent]
      elsif state[2][0] == Game.States[:Human] and state[0][2] == Game.States[:Open]
        state[0][2] = Game.States[:Opponent]
      elsif state[2][2] == Game.States[:Human] and state[0][0] == Game.States[:Open]
        state[0][0] = Game.States[:Opponent]
      else
        return false
      end

      return true
    end

    def self.any_corner state
      if state[2][2] == Game.States[:Open]
        state[2][2] = Game.States[:Opponent]
      elsif state[2][0] == Game.States[:Open]
        state[2][0] = Game.States[:Opponent]
      elsif state[0][2] == Game.States[:Open]
        state[0][2] = Game.States[:Opponent]
      elsif state[0][0] == Game.States[:Open]
        state[0][0] = Game.States[:Opponent]
      else 
        return false
      end

      return true
    end

    def self.first_available state
      AI._take_first_available state
      return true
    end

    def self._eval_state state, report_state
      if self._eval_rows state, report_state
        return true
      elsif self._eval_cols state, report_state
        return true
      elsif self._eval_ulbr state, report_state
        return true
      else
        return self._eval_blur state, report_state
      end
    end

    def self._eval_rows state, report_state
      0.upto(state.count - 1) do |row|
        linestate = LineState.new(
          lambda {|idx, who| state[row][idx] = who }
        )

        0.upto(state[row].count - 1) do |col|
          linestate.update state[row][col], col
        end

        if report_state.call(linestate)
          return true
        end
      end

      return false
    end
    
    def self._eval_cols state, report_state
      0.upto(state.count - 1) do |col|
        linestate = LineState.new(
          lambda {|idx, who| state[idx][col] = who}
        )

        0.upto(state[col].count - 1) do |row|
          linestate.update state[row][col], row
        end

        if report_state.call(linestate)
          return true
        end
      end

      return false
    end
  
    def self._eval_ulbr state, report_state
      linestate = LineState.new(
        lambda {|idx, who| state[idx][idx] = who}
      )

      0.upto(2) do |rowcol|
        linestate.update state[rowcol][rowcol], rowcol
      end

      return report_state.call(linestate)
    end

    def self._eval_blur state, report_state
      linestate = LineState.new(
        lambda {|idx, who| state[2 - idx][idx] = who}
      )

      0.upto(2) do |rowcol|
        linestate.update state[2 - rowcol][rowcol], rowcol
      end

      return report_state.call(linestate)
    end
  end

  class Sloppy
    def self.move state
      if 0 == rand(10)
        return JSON.dump(self.random_move(JSON.parse(state)))
      end
      return Minimax.move state
    end

    def self.random_move state
      moves = []

      for row in 0..2
        for col in 0..2
          if state[row][col] == Game.States[:Open]
            moves.append([row, col])
          end
        end
      end

      move = moves[rand(moves.count)]
      state[move[0]][move[1]] = Game.States[:Opponent]

      return state
    end
  end
end
