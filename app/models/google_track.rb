class GoogleTrack < ActiveRecord::Base
  belongs_to :google_playlist
  has_one :spotify_track, dependent: :destroy

  serialize :google_json, JSON
end
