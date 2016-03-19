class AddSpotifyIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :spotify_id, :string
  end
end
