require 'json'
require File.join(File.dirname(__FILE__), '../ai')

class AiController < ApplicationController
  def move
    board = params[:board]
    if ''.class == board.class
      board = JSON.parse(board)
    end

    respond_to do |format|
      format.json { render :json => AI.const_get(params[:ai]).move(board) }
    end
  end
end

# TODO: host on heroku
