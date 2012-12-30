class Game < ActiveRecord::Base
  attr_accessible :moves, :state, :status
  after_initialize

  @@States = {
    :Open => 0,
    :Human => 1,
    :Opponent => 2,
    :Tie => 3,
  }

  def self.States
    return @@States
  end

  def initialize *params
    super *params
    self.status = 0 unless self.status
    self.state = '[[0,0,0],[0,0,0],[0,0,0]]' unless self.state
    self.moves = '[]' unless self.moves
  end

  def self.winner board
    # TODO: BUG: add and not open to all below conditionals
    # TODO: return Open or Tie depending on free space, update logic that calls this to check that instead of then re-checking for available children

    for row in 0..2
      if board[row][0] == board[row][1] and board[row][1] == board[row][2]
        return board[row][0]
      end
    end

    for col in 0..2
      if board[0][col] == board[1][col] and board[1][col] == board[2][col]
        return board[0][col]
      end
    end

    if board[0][0] == board[1][1] and board[1][1] == board[2][2]
      return board[0][0]
    end

    if board[2][0] == board[1][1] and board[1][1] == board[0][2]
      return board[2][0]
    end
        
    return @@States[:Open]
  end
end
