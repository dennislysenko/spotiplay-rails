class GooglePlaylistSerializer < ActiveModel::Serializer
  attributes :id, :google_id, :name, :description, :should_sync, :has_spotify_playlist
end