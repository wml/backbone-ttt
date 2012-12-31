require 'json'
require 'game'

# TODO: alternate AIs
#   - finish heuristic AI
#   - make sloppy minimax take a random position instead of 1st open

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
        when Game.States[:Open]: @available.push(idx)
        when Game.States[:Human]: @human.push(idx)
        else @opponent.push(idx)
        end
      end

      def move idx
        @move_impl.call idx
      end
    end

    def self.move state
      rules = [
        :winning_move,
        :block_win,
        :fork,
        :block_fork,
        :center,
        :opposite_corner_or_any_corner,
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
          linestate.move linestate.available[0]
          return true
        end
        return false
      }
    end

    def self.block_win state
      return self._eval_state state, lambda { |linestate|
        if linestate.human.count == 2 and linestate.available.count > 0
          linestate.move linestate.available[0]
          return true
        end
        return false
      }
    end

    def self.fork state
      for row in 0..2
        for col in 0..2
          if Game.States[:Open] == state[row][col]
            state[row][col] = Game.States[:Opponent]
            opportunities = 0

            self._eval_state(
              state, lambda { |linestate|
                if linestate.opponent.count == 2 and linestate.available.count > 0
                  opportunities += 1
                end
                return false
              }
            )
    
            if opportunities >= 2
              return true
            end

            state[row][col] = Game.States[:Open]
          end
        end
      end
            
      return false
    end

    def self.block_fork state
      # 1) detect fork.
      # 2) if exists
      # 2a) place O everywhere we can create a win op.
      # 2b) if opponent block doesnt create a fork for him, take move
      # 3) directly block fork
            
      return false
    end

    def self.center state
      # TODO
      return false
    end

    def self.opposite_corner_or_any_corner state
      # TODO
      return false
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
          lambda {|idx| state[row][idx] = Game.States[:Opponent]}
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
          lambda {|idx| state[idx][col] = Game.States[:Opponent]}
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
        lambda {|idx| state[idx][idx] = Game.States[:Opponent]}
      )

      0.upto(2) do |rowcol|
        linestate.update state[rowcol][rowcol], rowcol
      end

      return report_state.call(linestate)
    end

    def self._eval_blur state, report_state
      linestate = LineState.new(
        lambda {|idx| state[2 - idx][idx] = Game.States[:Opponent]}
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
        return FirstAvailable.move state
      end
      return Minimax.move state
    end
  end
end
