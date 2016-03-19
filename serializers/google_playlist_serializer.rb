class GooglePlaylistSerializer < ActiveModel::Serializer
  attributes :google_id, :name, :description, :should_sync, :has_spotify_playlist
end