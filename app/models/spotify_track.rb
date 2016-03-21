class SpotifyTrack < ActiveRecord::Base
  belongs_to :spotify_playlist
  has_one :google_track, dependent: :destroy

  serialize :spotify_json, JSON
end
