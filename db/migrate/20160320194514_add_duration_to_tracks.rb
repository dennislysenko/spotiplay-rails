class AddDurationToTracks < ActiveRecord::Migration
  def change
    add_column :google_tracks, :duration_ms, :integer
    add_column :spotify_tracks, :duration_ms, :integer
  end
end
