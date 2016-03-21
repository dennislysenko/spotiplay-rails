class ChangeTrackJsonFieldsToText < ActiveRecord::Migration
  def change
    change_column :google_tracks, :google_json, :text
    change_column :spotify_tracks, :spotify_json, :text
  end
end
