class CreateSpotifyTracks < ActiveRecord::Migration
  def change
    create_table :spotify_tracks do |t|
      t.string :spotify_json
      t.string :spotify_id
      t.string :title
      t.string :artist
      t.string :album
      t.references :spotify_playlist, index: true, foreign_key: true
      t.references :google_track, index: true, foreign_key: true

      t.timestamps null: false
    end

    add_reference :google_tracks, :spotify_track, index: true, foreign_key: true
  end
end
