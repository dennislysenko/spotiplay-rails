class RemoveAnotherForeignKey < ActiveRecord::Migration
  def change
    remove_foreign_key :google_tracks, :spotify_tracks
  end
end
