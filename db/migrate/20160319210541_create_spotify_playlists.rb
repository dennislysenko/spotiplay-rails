class CreateSpotifyPlaylists < ActiveRecord::Migration
  def change
    create_table :spotify_playlists do |t|
      t.references :user, index: true, foreign_key: true
      t.references :google_playlist, index: true, foreign_key: true
      t.string :name
      t.text :spotify_json
      t.string :spotify_id

      t.timestamps null: false
    end
  end
end
