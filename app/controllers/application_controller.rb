class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user!
    @user ||= User.find(session[:user_id])
  end

  def logged_in?
    User.exists?(session[:user_id])
  end

  def current_user?
    if User.exists? session[:user_id]
      User.find session[:user_id]
    end
  end
end
