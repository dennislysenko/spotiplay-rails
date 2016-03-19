class User < ActiveRecord::Base

  # noinspection RubyStringKeysInHashInspection
  def rspotify_hash
    {
        'credentials' => { 'token' => spotify_access_token, 'refresh_token' => spotify_refresh_token },
        'info' => { 'id' => spotify_id }
    }
  end
end
