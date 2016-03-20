class SpotifyPlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :google_playlist

  def rspotify
    @rspotify ||= RSpotify::Playlist.find(user.spotify_id, spotify_id)
  end
end
