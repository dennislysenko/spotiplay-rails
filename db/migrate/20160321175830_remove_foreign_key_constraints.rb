class RemoveForeignKeyConstraints < ActiveRecord::Migration
  def change
    remove_foreign_key :spotify_tracks, :google_tracks
  end
end
