class GoogleController < ApplicationController
  def playlists
    # Load playlists from google play, make sure our local db is up to date with them
    playlists = current_user!.play.get('playlists')['playlists']
    stored_playlists = current_user!.google_playlists

    playlists.each do |playlist|
      stored_playlist = stored_playlists.find { |p| p.google_id == playlist['id']}
      attributes = {
          google_json: playlist,
          name: playlist['name'],
          description: playlist['description'],
      }
      if stored_playlist.nil?
        attributes.merge!({
            google_id: playlist['id'],
            should_sync: false
        })
        current_user!.google_playlists.create!(attributes)
      else
        stored_playlist.update!(attributes)
      end
    end

    stored_playlists = current_user!.google_playlists.order(name: :asc)

    render json: { playlists: stored_playlists.map { |playlist| GooglePlaylistSerializer.new(playlist).as_json } }
  end
end
