require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  setup do
    @game = games(:one_move)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:games)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create game" do
    assert_difference('Game.count') do
      post :create, { :format => :json, :game => { :board => @game.board } }
    end

    assert_response :success
  end

  test "create game fails if status sent" do
    post :create, { :format => :json, :game => { :status => 0, :board => @game.board } }

    assert_response :unprocessable_entity
  end

  test "create game fails if moves list sent" do
    post :create, { :format => :json, :game => { :moves => '[]', :board => @game.board } }

    assert_response :unprocessable_entity
  end

  test "create game fails if bogus parameter sent" do
    post :create, { :format => :json, :game => { :foo => 'bar', :board => @game.board } }

    assert_response :unprocessable_entity
  end

  test "should show game" do
    get :show, :id => @game
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @game
    assert_response :success
  end

  test "should update game" do
    put :update, {:format => :json, :id => @game, :game => { :board => '[[1,2,0],[0,0,0],[0,0,0]]' }}
    assert_response :success
  end

  test "should destroy game" do
    assert_difference('Game.count', -1) do
      delete :destroy, :id => @game
    end

    assert_redirected_to games_path
  end
end
