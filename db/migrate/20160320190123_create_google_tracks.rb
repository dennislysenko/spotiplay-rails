class CreateGoogleTracks < ActiveRecord::Migration
  def change
    create_table :google_tracks do |t|
      t.string :google_json
      t.string :google_entry_id
      t.string :google_id
      t.string :title
      t.string :artist
      t.string :album
      t.references :google_playlist, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
