class User < ActiveRecord::Base
  has_many :google_playlists, dependent: :destroy
  has_many :spotify_playlists, dependent: :destroy

  # noinspection RubyStringKeysInHashInspection
  def rspotify_hash
    {
        'credentials' => { 'token' => spotify_access_token, 'refresh_token' => spotify_refresh_token },
        'info' => { 'id' => spotify_id }
    }
  end

  def rspotify
    @rspotify ||= RSpotify::User.new(rspotify_hash)
  end

  class GooglePlayInterface
    def initialize(user)
      raise if user.nil?
      @user = user
    end

    def get(resource)
      JSON.parse(RestClient.get("#{ENV['NODE_HOST']}/#{resource}?#{auth.to_query}"))
    end

    private
    def auth
      { email: @user.google_email, password: @user.google_password_encrypted, iv: @user.google_password_iv }
    end
  end

  def play
    @play ||= GooglePlayInterface.new(self)
  end
end
