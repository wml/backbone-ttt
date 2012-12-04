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

      # TODO

      return JSON.dump(state)
    end
  end
end
