require "test/unit"

class MinimaxTest < Test::Unit::TestCase
  def setup
    @underTest = AI::Minimax
  end

  def test_only_move_is_taken
    onlyOneMove = '[[1,2,1],[1,2,2],[2,1,0]]'
    assert_equal('[[1,2,1],[1,2,2],[2,1,2]]', @underTest.move(onlyOneMove))
  end

  def test_winning_move_is_taken
    oneWinningMove = '[[1,1,2],[2,1,2],[1,0,0]]'
    assert_equal('[[1,1,2],[2,1,2],[1,0,2]]', @underTest.move(oneWinningMove))
  end

  def test_stalemate_chosen_over_loss
    stalemateOrLoss = '[[1,2,1],[2,2,1],[0,1,0]]'
    assert_equal('[[1,2,1],[2,2,1],[0,1,2]]', @underTest.move(stalemateOrLoss))
  end

  def test_forced_block_taken
    forcedBlock = '[[1,2,0],[1,0,0],[0,0,0]]'
    assert_equal('[[1,2,0],[1,0,0],[2,0,0]]', @underTest.move(forcedBlock))
  end

  # TODO: alpha beta pruning
end
