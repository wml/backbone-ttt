require 'json'
require 'game'

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
      return JSON.dump(self.algo(true, state, true))
    end

    def self.algo myturn, board, root
      score = self.score(board)
      children = self.children(myturn, board)

      if 0 == children.count or 0 != score
        return score
      end

      bestscore = nil
      bestmove = nil

      children.each do |child|
        score = self.algo((not myturn), child, false)

        if nil == bestscore or \
          ((myturn and score > bestscore) or (not myturn and score < bestscore))
          bestscore = score
          bestmove = child
        end
      end

      if root
        return bestmove
      else
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

      for row in 0..2
        if board[row][0] == board[row][1] and board[row][1] == board[row][2]
          return scores[board[row][0]]
        end
      end

      for col in 0..2
        if board[0][col] == board[1][col] and board[1][col] == board[2][col]
          return scores[board[0][col]]
        end
      end

      if board[0][0] == board[1][1] and board[1][1] == board[2][2]
          return scores[board[0][0]]
      end

      if board[2][0] == board[1][1] and board[1][1] == board[0][2]
          return scores[board[2][0]]
      end
        
      return 0
    end
  end
end
