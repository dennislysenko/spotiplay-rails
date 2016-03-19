class GooglePlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :spotify_playlist
end
