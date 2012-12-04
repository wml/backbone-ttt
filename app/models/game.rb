class Game < ActiveRecord::Base
  attr_accessible :moves, :state, :status
  after_initialize

  def initialize params
    super params
    self.status = 0 unless self.status
    self.state = '[[0,0,0],[0,0,0],[0,0,0]]' unless self.state
    self.moves = '[]' unless self.moves
  end
end
