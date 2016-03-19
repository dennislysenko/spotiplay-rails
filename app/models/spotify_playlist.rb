class SpotifyPlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :google_playlist
end
