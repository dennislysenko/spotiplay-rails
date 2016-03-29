class GooglePlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :spotify_playlist, dependent: :destroy
  has_many :google_tracks, dependent: :destroy

  serialize :google_json, JSON

  scope :to_sync, -> { where should_sync: true }

  def has_spotify_playlist
    spotify_playlist.present?
  end
end
