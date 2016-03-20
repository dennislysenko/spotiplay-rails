class Syncer
  include Sidekiq::Worker

  @queue = :high # is this even a thing with sidekiq or a carryover from my old resque code?

  def perform
    errors = []

    User.all.each do |user|
      playlists = user.google_playlists.to_sync
      next if playlists.empty?

      # load playlist entries for user
      response = user.play.get('playlist_entries')
      unorganized_entries = response['entries']

      playlists_to_entries = {} # playlists to arrays of their entries

      unorganized_entries.each do |entry|
        playlist_id = entry['playlistId']
        playlist = playlists.find_by(google_id: playlist_id)

        next if playlist.nil? # not sure, but we're dealing with an undocumented API here so let's just be safe...

        playlists_to_entries[playlist] ||= []
        playlists_to_entries[playlist] << entry
      end

      playlists_to_entries.each do |playlist, entries|
        error = sync_playlist_returning_error(playlist, entries)

        if error.present?
          errors << error
        end
      end
    end

    raise errors.first unless errors.empty? # TODO: raise all the errors
  end

  def sync_playlist_returning_error(playlist, entries)
    if playlist.spotify_playlist.nil?
      rspotify_playlist = playlist.user.rspotify.create_playlist!(playlist.name)
      playlist.spotify_playlist = playlist.user.spotify_playlists.create!(
          name: rspotify_playlist.name,
          spotify_id: rspotify_playlist.id
      )
      playlist.save!
    end

    # sync tracks
    entries.each do |entry|

    end

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