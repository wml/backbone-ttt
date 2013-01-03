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
end

class HeuristicTest <  Test::Unit::TestCase
  def setup
    @underTest = AI::Heuristic
  end

  def test_winning_row_move_is_taken
    oneWinningMove = '[[1,2,1],[2,2,0],[1,1,0]]'
    assert_equal('[[1,2,1],[2,2,2],[1,1,0]]', @underTest.move(oneWinningMove))
  end

  def test_winning_row_move_is_taken_over_block
    winOrBlock = '[[1,1,0],[2,2,0],[1,0,0]]'
    assert_equal('[[1,1,0],[2,2,2],[1,0,0]]', @underTest.move(winOrBlock))
  end

  def test_row_block_is_taken_when_no_win_present
    oneBlock = '[[1,1,0],[2,0,0],[0,0,0]]'
    assert_equal('[[1,1,2],[2,0,0],[0,0,0]]', @underTest.move(oneBlock))
  end

  def test_winning_col_move_is_taken
    oneWinningMove = '[[1,2,1],[2,2,1],[1,0,0]]'
    assert_equal('[[1,2,1],[2,2,1],[1,2,0]]', @underTest.move(oneWinningMove))
  end

  def test_winning_col_move_is_taken_over_block
    winOrBlock = '[[1,2,1],[1,2,0],[0,0,0]]'
    assert_equal('[[1,2,1],[1,2,0],[0,2,0]]', @underTest.move(winOrBlock))
  end

  def test_col_block_is_taken_when_no_win_present
    oneBlock = '[[1,2,0],[1,0,0],[0,0,0]]'
    assert_equal('[[1,2,0],[1,0,0],[2,0,0]]', @underTest.move(oneBlock))
  end

  def test_ulbr_diagonal_win_taken
    diagonalWin = '[[2,1,1],[1,2,0],[0,0,0]]'
    assert_equal('[[2,1,1],[1,2,0],[0,0,2]]', @underTest.move(diagonalWin))
  end

  def test_ulbr_diagonal_block_taken
    diagonalBlock = '[[1,2,0],[2,1,0],[0,1,0]]'
    assert_equal('[[1,2,0],[2,1,0],[0,1,2]]', @underTest.move(diagonalBlock))
  end

  def test_blur_diagonal_win_taken
    diagonalWin = '[[1,0,0],[1,2,1],[2,0,0]]'
    assert_equal('[[1,0,2],[1,2,1],[2,0,0]]', @underTest.move(diagonalWin))
  end

  def test_blur_diagonal_block_taken
    diagonalBlock = '[[0,2,1],[0,0,0],[1,0,0]]'
    assert_equal('[[0,2,1],[0,2,0],[1,0,0]]', @underTest.move(diagonalBlock))
  end

  def test_fork_taken
    forkable = '[[2,1,1],[1,0,0],[2,0,0]]'
    assert_equal('[[2,1,1],[1,0,0],[2,0,2]]', @underTest.move(forkable))
  end

  def test_fork_preempted_by_forced_block
    preemptable = '[[0,0,1],[0,2,0],[1,0,0]]'
    assert_equal('[[0,0,1],[2,2,0],[1,0,0]]', @underTest.move(preemptable))
  end

  def test_fork_blocked
    direct_block_required = '[[1,2,0],[0,0,0],[0,1,0]]'
    assert_equal('[[1,2,0],[0,0,0],[2,1,0]]', @underTest.move(direct_block_required))
  end

  def test_center_preferable_if_no_wins_or_blocks
    no_advantage = '[[1,0,0],[0,0,0],[0,0,0]]'
    assert_equal('[[1,0,0],[0,2,0],[0,0,0]]', @underTest.move(no_advantage))
  end

  def test_opposite_corner_preferable_if_center_taken
    opposite_corner_open = '[[1,0,0],[0,2,0],[0,0,0]]'
    assert_equal('[[1,0,0],[0,2,0],[0,0,2]]', @underTest.move(opposite_corner_open))
  end

  def test_any_corner_preferable_to_side
    no_advantage_center_taken = '[[0,0,0],[0,1,0],[0,0,0]]'
    assert_equal(
      '[[0,0,0],[0,1,0],[0,0,2]]',
      @underTest.move(no_advantage_center_taken)
    )
  end

  def test_side_taken_by_default
    no_good_move = '[[2,1,2],[0,1,0],[1,2,1]]'
    assert_equal('[[2,1,2],[2,1,0],[1,2,1]]', @underTest.move(no_good_move))
  end
end
