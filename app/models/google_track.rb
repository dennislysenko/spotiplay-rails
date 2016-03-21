class GoogleTrack < ActiveRecord::Base
  belongs_to :google_playlist
  has_one :spotify_track
  serialize :google_json, JSON
end
