class WelcomeController < ApplicationController
  def index
    @logged_in = logged_in?
    @current_user = current_user
  end

  def spotify_test
    user = RSpotify::User.new(current_user.rspotify_hash)
    render json: user.playlists
  rescue Exception => e
    raise "fuck"
  end

  protected

  def current_user
    @user ||= User.find(session[:user_id])
  end

  def logged_in?
    User.exists?(session[:user_id])
  end
end
