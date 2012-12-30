require File.join(File.dirname(__FILE__), '../ai')

class AiController < ApplicationController
  def move
    respond_to do |format|
      format.json { render :json => AI.const_get(params[:ai]).move(params[:state]) }
    end
  end
end

# TODO: move to mongo database
# TODO: move to heroku
# TODO: configurable first-turn (human always gets X as of now)
# TODO: alternate AIs
#       - precomputed AI
#       - rule-based [heuristic] AI (as described on wikipedia)
