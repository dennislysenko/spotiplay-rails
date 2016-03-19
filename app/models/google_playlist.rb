class GooglePlaylist < ActiveRecord::Base
  belongs_to :user
  has_one :spotify_playlist

  scope :to_sync, -> { where should_sync: true }

  def has_spotify_playlist
    spotify_playlist.present?
  end
end
