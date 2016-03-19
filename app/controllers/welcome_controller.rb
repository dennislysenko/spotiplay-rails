class WelcomeController < ApplicationController
  def index
    @logged_in = logged_in?
    @current_user = current_user
  end

  def spotify_test
    render json: current_user.rspotify.playlists
  end

  def play_test
    render json: current_user.play.get('playlists')
  end

  protected

  def current_user
    @user ||= User.find(session[:user_id])
  end

  def logged_in?
    User.exists?(session[:user_id])
  end
end
