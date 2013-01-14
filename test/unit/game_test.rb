require 'test_helper'

class GameTest < ActiveSupport::TestCase
  setup :setup_game
  def setup_game
    @underTest = Game.new
  end

  test "new game initializes empty board" do
    assert_equal Game.EmptyBoard, @underTest.board
  end

  test "new game initializes empty moves list" do
    assert_equal [], @underTest.moves
  end

  test "new game initializes status to Open" do
    assert_equal Game.States[:Open], @underTest.status    
  end

  test "move updates board state to reflect move" do
    board = [[1,0,0],[0,0,0],[0,0,0]]
    @underTest.move board
    assert_equal board, @underTest.board
  end

  test "move appends board state to empty moves list" do
    board = [[1,0,0],[0,0,0],[0,0,0]]
    @underTest.move board
    assert_equal [board], @underTest.moves
  end

  test "second move results in updated moves list" do
    first = [[1,0,0],[0,0,0],[0,0,0]]
    second = [[1,2,0],[0,0,0],[0,0,0]]
    @underTest.move first
    @underTest.move second
    assert_equal [first, second], @underTest.moves
  end

  test "human winning move results in updated status" do
    moves = [
      [[1,0,0],[0,0,0],[0,0,0]],
      [[1,2,0],[0,0,0],[0,0,0]],
      [[1,2,0],[1,0,0],[0,0,0]],
      [[1,2,2],[1,0,0],[0,0,0]],
      [[1,2,2],[1,0,0],[1,0,0]]
    ]

    for move in moves
      @underTest.move move
    end

    assert_equal Game.States[:Human], @underTest.status
  end

  test "opponent winning move results in updated status" do
    moves = [
      [[1,0,0],[0,0,0],[0,0,0]],
      [[1,2,0],[0,0,0],[0,0,0]],
      [[1,2,0],[1,0,0],[0,0,0]],
      [[1,2,0],[1,2,0],[0,0,0]],
      [[1,2,0],[1,2,0],[0,0,1]],
      [[1,2,0],[1,2,0],[0,2,1]],
    ]

    for move in moves
      @underTest.move move
    end

    assert_equal Game.States[:Opponent], @underTest.status
  end

  test "non game ending move does not change status" do
    @underTest.move [[0,1,0],[1,0,0],[0,0,0]]
    assert_equal Game.States[:Open], @underTest.status
  end

  test "non winning last slot move results in tied game status" do
    ending_board = [[1,1,2],[2,2,1],[1,2,1]]
    working_board = [[0,0,0],[0,0,0],[0,0,0]]
    for row in 0..2
      for col in 0..2
        working_board[row][col] = ending_board[row][col]
        @underTest.move working_board
      end
    end
    assert_equal Game.States[:Tie], @underTest.status
  end
end

class BoardSerializerTest < ActiveSupport::TestCase
  @@underTest = Game::BoardSerializer

  test "inverse operations preserve empty board" do
    _test_impl [[0,0,0],[0,0,0],[0,0,0]]
  end

  test "inverse operations preserve board with X" do
    _test_impl [[0,1,0],[0,0,0],[0,0,0]]
  end

  test "inverse operations preserve board with X and O" do
    _test_impl [[0,1,0],[0,2,0],[0,0,0]]
  end

  test "inverse operations preserve board with moves in high slots" do
    _test_impl [[0,1,0],[0,2,1],[0,0,2]]
  end

  test "inverse operations preserve full board" do
    _test_impl [[1,1,2],[2,2,1],[1,1,2]]
  end

  def _test_impl board
    result = @@underTest.load(@@underTest.dump(board))
    assert_equal board, result
  end
end


class MovesSerializerTest < ActiveSupport::TestCase
  @@underTest = Game::MovesSerializer

  test "inverse operations preserve empty moves list" do
    assert_equal [], @@underTest.load(@@underTest.dump([]))
  end

  test "inverse operations preserve single moves list" do
    moves = [[[1,0,0],[0,0,0],[0,0,0]]]
    assert_equal moves, @@underTest.load(@@underTest.dump(moves))
  end

  test "inverse operations preserve moves list of size 2" do
    moves = [
      [[1,0,0],[0,0,0],[0,0,0]],
      [[1,0,0],[0,2,0],[0,0,0]],
    ]
    assert_equal moves, @@underTest.load(@@underTest.dump(moves))
  end

  test "inverse operations preserve full game" do
    moves = [
      [[1,0,0],[0,0,0],[0,0,0]],
      [[1,0,0],[0,2,0],[0,0,0]],
      [[1,0,0],[0,2,0],[0,0,1]],
      [[1,0,0],[0,2,0],[0,2,1]],
      [[1,1,0],[0,2,0],[0,2,1]],
      [[1,1,2],[0,2,0],[0,2,1]],
      [[1,1,2],[0,2,0],[1,2,1]],
      [[1,1,2],[2,2,0],[1,2,1]],
      [[1,1,2],[2,2,1],[1,2,1]],
    ]
    assert_equal moves, @@underTest.load(@@underTest.dump(moves))
  end
end

class GameValidatorTest < ActiveSupport::TestCase
  setup :setup_under_test

  def setup_under_test
    @record = games(:one_move)
    @underTest = Game::GameValidator.new({ })
  end

  test "create with one move validates" do
    @underTest.validate @record
    assert_equal 0, @record.errors.count
  end

  test "one additional move validates" do
    @record.move [[1,2,0],[0,0,0],[0,0,0]]
    @underTest.validate @record
    assert_equal 0, @record.errors.count
  end

  test "two moves are rejected" do
    @record.move [[1,2,1],[0,0,0],[0,0,0]]
    @underTest.validate @record
    assert_equal 1, @record.errors.count
  end

  test "changed move is rejected" do
    @record.move [[2,0,0],[0,0,0],[0,0,0]]
    @underTest.validate @record
    assert @record.errors[:board][0].include?('1 -> 2')
  end

  test "cleared move is rejected" do
    @record.move [[0,0,0],[0,0,0],[0,0,0]]
    @underTest.validate @record
    assert @record.errors[:board][0].include?('1 -> 0')
  end

  test "illegal move is rejected" do
    @record.move [[1,3,0],[0,0,0],[0,0,0]]
    @underTest.validate @record
    assert @record.errors[:board][0] == 'illegal move [3]'
  end

  test "out of order move is rejected" do
    @record.move [[1,0,1],[0,0,0],[0,0,0]]
    @underTest.validate @record
    assert_equal 1, @record.errors.count
  end

  test "status changing move after game over is rejected" do
    moves = [
      [[1,0,0],[2,0,0],[0,0,0]],
      [[1,0,0],[2,0,0],[1,0,0]],
      [[1,0,0],[2,2,0],[1,0,0]],
      [[1,0,0],[2,2,0],[1,1,0]],
      [[1,2,0],[2,2,0],[1,1,0]],
      [[1,2,0],[2,2,0],[1,1,1]],
    ]

    for move in moves
      @record.move move
      @record.save
    end

    @record.move [[1,2,0],[2,2,2],[1,1,1]]
    @underTest.validate @record
    assert_equal 1, @record.errors.count
  end

  test "non status changing move after game over is rejected" do
    moves = [
      [[1,0,0],[2,0,0],[0,0,0]],
      [[1,1,0],[2,0,0],[0,0,0]],
      [[1,1,0],[2,2,0],[0,0,0]],
      [[1,1,1],[2,2,0],[0,0,0]],
    ]

    for move in moves
      @record.move move
      @record.save
    end

    @record.move [[1,1,1],[2,2,0],[2,0,0]]
    @underTest.validate @record
    assert_equal 1, @record.errors.count
  end
end
