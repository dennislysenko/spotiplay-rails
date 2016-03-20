class WelcomeController < ApplicationController
  def index
    @logged_in = logged_in?
    @current_user = current_user?
  end

  def spotify_test
    playlists = current_user!.rspotify.playlists
    render json: playlists
  end

  def play_test
    render json: current_user!.play.get('all_tracks')
  end

  protected
  def logged_in?
    User.exists?(session[:user_id])
  end
end
