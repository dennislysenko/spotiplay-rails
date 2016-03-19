class Syncer
  include Sidekiq::Worker

  @queue = :high # is this even a thing with sidekiq or a carryover from my old resque code?

  def perform
    errors = []
    GooglePlaylist.to_sync.each do |playlist|
      error = sync_playlist(playlist)

      if error.present?
        errors << error
      end
    end

    raise errors.first unless errors.empty? # TODO: raise all the errors
  end

  def sync_playlist(playlist)
    if playlist.spotify_playlist.nil?
      rspotify_playlist = playlist.user.rspotify.create_playlist!(playlist.name)
      playlist.spotify_playlist = playlist.user.spotify_playlists.create!(
          name: rspotify_playlist.name,
          spotify_id: rspotify_playlist.id
      )
      playlist.save!
    end

    # sync tracks

    return nil
  rescue => e
    return e
  end
end

# schedule this job once a minute
Sidekiq::Cron::Job.create(
    name: 'Syncer: syncs google play playlists to spotify',
    cron: '* * * * *',
    class: 'Syncer'
)