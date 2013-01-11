require File.join(File.dirname(__FILE__), '../ai')

class AiController < ApplicationController
  def move
    respond_to do |format|
      format.json { render :json => AI.const_get(params[:ai]).move(params[:board]) }
    end
  end
end

# TODO: host on heroku
