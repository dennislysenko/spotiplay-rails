class GooglePlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :spotify_playlist

  def has_spotify_playlist
    spotify_playlist.present?
  end
end
