class SpotifyPlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :google_playlist, dependent: :destroy
  has_many :spotify_tracks, dependent: :destroy

  serialize :spotify_json, JSON

  def rspotify
    @rspotify ||= RSpotify::Playlist.find(spotify_author_id, spotify_id)
  end
end
