class AddSyncOptionsToGooglePlaylists < ActiveRecord::Migration
  def change
    add_column :google_playlists, :should_sync, :boolean
    add_reference :google_playlists, :spotify_playlist, index: true, foreign_key: true
  end
end
