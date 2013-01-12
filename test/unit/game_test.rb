require 'test_helper'

class BoardSerializerTest < ActiveSupport::TestCase
  @@underTest = Game::BoardSerializer

  test "inverse operations preserve empty board" do
    _test_impl '[[0,0,0],[0,0,0],[0,0,0]]'
  end

  test "inverse operations preserve board with X" do
    _test_impl '[[0,1,0],[0,0,0],[0,0,0]]'
  end

  test "inverse operations preserve board with X and O" do
    _test_impl '[[0,1,0],[0,2,0],[0,0,0]]'
  end

  test "inverse operations preserve board with moves in high slots" do
    _test_impl '[[0,1,0],[0,2,1],[0,0,2]]'
  end

  test "inverse operations preserve full board" do
    _test_impl '[[1,1,2],[2,2,1],[1,1,2]]'
  end

  def _test_impl board
    result = @@underTest.load(@@underTest.dump(board))
    assert_equal board, result
  end
end

# TODO: all JSON.X calls - update f/e to expect json arrays back, get rid of that marshalling
# TODO: rip out unnecessary scaffolding and update games list view
# TODO: "moves" only tracked on server, don't marshal back or track in backbone models
# TODO: eliminate moves validation because the user can't change it, once above TODO accomplished.
class MovesSerializerTest < ActiveSupport::TestCase
  @@underTest = Game::MovesSerializer

  test "inverse operations preserve empty moves list" do
    assert_equal "[]", @@underTest.load(@@underTest.dump("[]"))
  end

  test "inverse operations preserve single moves list" do
    moves = JSON.dump([
      [[1,0,0],[0,0,0],[0,0,0]]
    ])
    assert_equal moves, @@underTest.load(@@underTest.dump(moves))
  end

  test "inverse operations preserve moves list of size 2" do
    moves = JSON.dump([
      [[1,0,0],[0,0,0],[0,0,0]],
      [[1,0,0],[0,2,0],[0,0,0]],
    ])
    assert_equal moves, @@underTest.load(@@underTest.dump(moves))
  end

  test "inverse operations preserve full game" do
    moves = JSON.dump([
      [[1,0,0],[0,0,0],[0,0,0]],
      [[1,0,0],[0,2,0],[0,0,0]],
      [[1,0,0],[0,2,0],[0,0,1]],
      [[1,0,0],[0,2,0],[0,2,1]],
      [[1,1,0],[0,2,0],[0,2,1]],
      [[1,1,2],[0,2,0],[0,2,1]],
      [[1,1,2],[0,2,0],[1,2,1]],
      [[1,1,2],[2,2,0],[1,2,1]],
      [[1,1,2],[2,2,1],[1,2,1]],
    ])
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
    @record.board = '[[1,2,0],[0,0,0],[0,0,0]]'
    @underTest.validate @record
    assert_equal 0, @record.errors.count
  end

  test "two moves are rejected" do
    @record.board = '[[1,2,1],[0,0,0],[0,0,0]]'
    @underTest.validate @record
    assert_equal 1, @record.errors.count
  end

  test "changed move is rejected" do
    @record.board = '[[2,0,0],[0,0,0],[0,0,0]]'
    @underTest.validate @record
    assert @record.errors[:board][0].include?('1 -> 2')
  end

  test "cleared move is rejected" do
    @record.board = '[[0,0,0],[0,0,0],[0,0,0]]'
    @underTest.validate @record
    assert @record.errors[:board][0].include?('1 -> 0')
  end

  test "illegal move is rejected" do
    @record.board = '[[1,3,0],[0,0,0],[0,0,0]]'
    @underTest.validate @record
    assert @record.errors[:board][0] == 'illegal move [3]'
  end

  test "out of order move is rejected" do
    @record.board = '[[1,0,1],[0,0,0],[0,0,0]]'
    @underTest.validate @record
    assert_equal 1,  @record.errors.count
  end
end
