require 'json'
require 'game'

# TODO: alternate AIs
#       - precomputed AI
#       - rule-based [heuristic] AI (as described on wikipedia)
#       - make sloppy minimax take a random position instead of 1st open

module AI
  class FirstAvailable 
    def self.move state
      state = JSON.parse(state)

      0.upto(state.count - 1) do |row|
        0.upto(state[row].count - 1) do |col|
          if Game.States[:Open] == state[row][col]
            state[row][col] = Game.States[:Opponent]
            return JSON.dump(state)
          end
        end
      end

    end
  end

  class Minimax
    def self.move state
      state = JSON.parse(state)
      solutions = { }
      return JSON.dump(self.algo(true, state, true, solutions, 1, -100, 100))
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

  class Sloppy
    def self.move state
      if 0 == rand(10)
        return FirstAvailable.move state
      end
      return Minimax.move state
    end
  end

  class Heuristic
    def self.move state
      # TODO --------------------
      # 1. check for win
      # 2. block opponent win
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
  end
end
