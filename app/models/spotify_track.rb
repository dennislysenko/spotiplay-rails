class SpotifyTrack < ActiveRecord::Base
  belongs_to :spotify_playlist
  has_one :google_track

  serialize :spotify_json, JSON
end
