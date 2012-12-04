class Game < ActiveRecord::Base
  attr_accessible :moves, :state, :status
  after_initialize

  @@States = {
    :Open => 0,
    :Human => 1,
    :Opponent => 2
  }

  def self.States
    return @@States
  end

  def initialize params
    super params
    self.status = 0 unless self.status
    self.state = '[[0,0,0],[0,0,0],[0,0,0]]' unless self.state
    self.moves = '[]' unless self.moves
  end
end
