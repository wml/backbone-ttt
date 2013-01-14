class GamesController < ApplicationController
  # GET /games
  # GET /games.json
  def index
    respond_to do |format|
      format.html { @games = Game.last(10).reverse } # index.html.erb
      format.json { render :json => Game.all }
    end
  end

  # GET /games/1
  # GET /games/1.json
  def show
    @game = Game.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @game }
    end
  end

  # POST /games.json
  def create
    game_params = params[:game]
    if not validate_params(game_params)
      return
    end

    @game = Game.new
    @game.move game_params[:board]

    respond_to do |format|
      if @game.save
        format.json { render :json => @game, :status => :created, :location => @game }
      else
        format.json { render :json => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /games/1.json
  def update
    game_params = params[:game]
    if not validate_params(game_params)
      return
    end

    @game = Game.find(params[:id])
    @game.move game_params[:board]


    respond_to do |format|
      if @game.save
        format.json { head :no_content }
      else
        format.json { render :json => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  def validate_params game_params
    if game_params.count != 1 or not game_params.member?(:board)
      respond_to do |format|
        format.json { render :json => {:board => ["exactly one parameter is expected to this API: `board'"]}, :status => :unprocessable_entity }
      end
      return false
    end
    return true
  end
end
