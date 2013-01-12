require 'json'

class Game < ActiveRecord::Base
  class BoardSerializer
    def self.load(from_db)
      result = []
      from_db = from_db.to_i

      for r in 0..2
        row = []
        for c in 0..2
          row.unshift (from_db & 0x3)
          from_db >>= 2
        end
        result.unshift row
      end

      return JSON.dump(result)
    end

    def self.dump(to_db)
      result = 0
      to_db = JSON.parse(to_db)

      for r in 0..2
        for c in 0..2
          result <<= 2
          result |= to_db[r][c]
        end
      end

      result &= 0x3FFFF
      return result
    end
  end

  class MovesSerializer
    def self.load(from_db)
      result = []
      from_db = from_db.to_i
      from_db = 0xFFFFFFFF unless from_db != 0
      board = [[0,0,0],[0,0,0],[0,0,0]]
      player = 0

      for i in 1..9
        move = from_db & 0x7
        from_db >>= 3

        if move == 7
          next_bit = from_db & 0x1
          from_db >>= 1
          if next_bit == 1
            next_bit = from_db & 0x1
            from_db >>= 1
            if next_bit == 1
              break
            end
            move = 8
          end
        end

        row = move % 3
        col = move / 3
          
        board[row][col] = 1 + player
        player = (player + 1) % 2

        result.push([board[0].clone, board[1].clone, board[2].clone])
      end
      
      return JSON.dump(result)
    end

    def self.dump(to_db)
      board = [[0,0,0],[0,0,0],[0,0,0]]
      to_db = JSON.parse(to_db) if ''.class == to_db.class
      result = 0xFFFFFFFF

      moves = []
      for state in to_db
        moves.push self.diff(board, state)
        board = state
      end

      for move in moves.reverse
        packed = move[0] + move[1] * 3
        if packed == 7
          result <<= 4
        elsif packed == 8
          result <<= 5
          packed |= 0x7
        else
          result <<= 3
        end
        result |= packed
      end

      return result & 0xFFFFFFFF
    end

    def self.diff board, state
      for row in 0..2
        for col in 0..2
          if board[row][col] != state[row][col]
            return [row, col]
          end
        end
      end
    end
  end

  class GameValidator < ActiveModel::Validator
    def validate(record)
      GameValidator.validate_status(record)
      GameValidator.validate_board(record)
      GameValidator.validate_moves(record)
    end

    def self.validate_board(record)
      board_changes = record.changes[:board]
      current = record.board
      last = (nil != board_changes ? board_changes[0] : Game.EmptyBoard)
      moves = 0
      slots = { 
        Game.States[:Human].to_s => 0, 
        Game.States[:Opponent].to_s => 0 
      }

      for i in 0.upto(current.length - 1)
        if current[i] != last[i]
          moves += 1
          if last[i] != Game.States[:Open].to_s
            record.errors[:board] << "non-empty slots may not be changed (#{last[i]} -> #{current[i]})"
          elsif not slots.include? current[i]
            record.errors[:board] << "illegal move [#{current[i]}]"
          end
        end
        if slots.include? current[i]
          slots[current[i]] += 1
        end
      end

      if 1 != moves
        record.errors[:board] << 'one move must be made per save'
      end

      if not (0..1).member?(
        slots[Game.States[:Human].to_s] -
        slots[Game.States[:Opponent].to_s]
      )
        record.errors[:board] << 'turns must alternate between the human and computer opponent, with the human moving first'
      end
    end
    
    def self.validate_status(record)
    end

    def self.validate_moves(record)
    end
  end

  attr_accessible :moves, :board, :status
  serialize :board, BoardSerializer
  serialize :moves, MovesSerializer
  include ActiveModel::Validations
  validates_with GameValidator

  @@States = {
    :Open => 0,
    :Human => 1,
    :Opponent => 2,
    :Tie => 3,
  }
  @@EmptyBoard = "[[0,0,0],[0,0,0],[0,0,0]]"

  def self.States
    return @@States
  end

  def self.EmptyBoard
    return @@EmptyBoard
  end

  def initialize *params
    super *params
    self.status = @@States[:Open] unless self.status
    self.board = 0 unless self.board
    self.moves = 0xFFFFFFFF unless self.moves
  end

  def self.winner board
    for row in 0..2
      if board[row][0] == board[row][1] and board[row][1] == board[row][2] \
        and board[row][0] != @@States[:Open]
        return board[row][0]
      end
    end

    for col in 0..2
      if board[0][col] == board[1][col] and board[1][col] == board[2][col] \
        and board[0][col] != @@States[:Open]
        return board[0][col]
      end
    end

    if board[0][0] == board[1][1] and board[1][1] == board[2][2] \
      and board[0][0] != @@States[:Open]
      return board[0][0]
    end

    if board[2][0] == board[1][1] and board[1][1] == board[0][2] \
      and board[2][0] != @@States[:Open]
      return board[2][0]
    end
        
    return @@States[:Open]
  end
end
