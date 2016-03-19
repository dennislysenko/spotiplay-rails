class AddUserToGooglePlaylists < ActiveRecord::Migration
  def change
    add_reference :google_playlists, :user, index: true, foreign_key: true
    remove_reference :google_playlists, :user_id, index: true, foreign_key: true
  end
end
