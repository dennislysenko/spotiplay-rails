class GooglePlaylistsController < ApplicationController
  def index
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

    render json: { playlists: stored_playlists.map { |playlist| GooglePlaylistSerializer.new(playlist, root: false).as_json } }
  end

  def update
    @playlist = GooglePlaylist.find(params[:id])
    @playlist.update!(update_params)
    render json: GooglePlaylistSerializer.new(@playlist)
  end

  private

  def update_params
    params.require(:google_playlist).permit(:should_sync)
  end
end
