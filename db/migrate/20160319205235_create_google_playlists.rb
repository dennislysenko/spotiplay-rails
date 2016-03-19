class CreateGooglePlaylists < ActiveRecord::Migration
  def change
    create_table :google_playlists do |t|
      t.string :google_id
      t.string :name
      t.string :description
      t.text :google_json

      t.timestamps null: false
    end
  end
end
