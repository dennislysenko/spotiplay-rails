class SpotifyPlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :google_playlist
  has_many :spotify_tracks, dependent: :destroy

  serialize :spotify_json, JSON

  def rspotify
    @rspotify ||= RSpotify::Playlist.find(user.spotify_id, spotify_id)
  end
end
