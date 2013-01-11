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

