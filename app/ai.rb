require 'json'
require 'game'

# TODO: alternate AIs
#       - precomputed AI
#       - rule-based [heuristic] AI (as described on wikipedia)
#       - make sloppy minimax take a random position instead of 1st open

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
    def self.move state
      rules = [
        :winning_move_or_block,
        :fork_or_block_fork,
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
   
    def self.winning_move_or_block state
      won = self._eval_wins(
        state, lambda {|humanslots, opponentslots| opponentslots == 2 }
      )

      if won 
        return true
      end

      return self._eval_wins(
        state, lambda {|humanslots, opponentslots| humanslots == 2 }
      )
    end

    def self._eval_wins state, condition_for_move
      initstate = lambda do
        return {
          :Open => -1,
          :Human => 0,
          :Opponent => 0
        }
      end

      updatestate = lambda do |slot, linestate, idx|
        case slot
          when Game.States[:Open]: linestate[:Open] = idx
          when Game.States[:Human]: linestate[:Human] += 1
          else linestate[:Opponent] += 1
        end
      end

      0.upto(state.count - 1) do |row|
        linestate = initstate.call()

        0.upto(state[row].count - 1) do |col|
          updatestate.call(state[row][col], linestate, col)
        end

        if linestate[:Open] != -1 and \
          condition_for_move.call(linestate[:Human], linestate[:Opponent])
          state[row][linestate[:Open]] = Game.States[:Opponent]
          return true
        end
      end

      0.upto(state.count - 1) do |col|
        linestate = initstate.call()

        0.upto(state[col].count - 1) do |row|
          updatestate.call(state[row][col], linestate, row)
        end

        if linestate[:Open] != -1 and \
          condition_for_move.call(linestate[:Human], linestate[:Opponent])
          state[linestate[:Open]][col] = Game.States[:Opponent]
          return true
        end
      end
  
      linestate = initstate.call()
      0.upto(2) do |rowcol|
        updatestate.call(state[rowcol][rowcol], linestate, rowcol)
      end
      if linestate[:Open] != -1 and \
        condition_for_move.call(linestate[:Human], linestate[:Opponent])
        state[linestate[:Open]][linestate[:Open]] = Game.States[:Opponent]
        return true
      end

      linestate = initstate.call()
      0.upto(2) do |rowcol|
        updatestate.call(state[2 - rowcol][rowcol], linestate, rowcol)
      end
      if linestate[:Open] != -1 and \
        condition_for_move.call(linestate[:Human], linestate[:Opponent])
        state[2 - linestate[:Open]][linestate[:Open]] = Game.States[:Opponent]
        return true
      end

      return false
    end

    def self.fork_or_block_fork state
      # TODO
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

      # TODO --------------------
      # 3. check for fork
      # 4. block opponent's fork
      #    1. by setting up 2 in a row to force a block, so long as the block doesn't allow for a fork (diagonal with you in center, dont play corner)
      #    2. block the fork directly
      # 5. play center if available
      # 6. play opposite corner if available
      # 7. play any corner if available
      # 8. play a side
      # END algorithm
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
