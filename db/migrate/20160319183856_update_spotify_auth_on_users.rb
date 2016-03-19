class UpdateSpotifyAuthOnUsers < ActiveRecord::Migration
  def change
    add_column :users, :spotify_access_token, :string
    add_column :users, :spotify_refresh_token, :string
    remove_column :users, :spotify_auth_hash, :text
  end
end
