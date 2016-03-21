class AddSpotifyAuthorIdToSpotifyPlaylists < ActiveRecord::Migration
  def change
    add_column :spotify_playlists, :spotify_author_id, :string
  end
end
