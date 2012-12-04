class Game < ActiveRecord::Base
  attr_accessible :moves, :state, :status
end
