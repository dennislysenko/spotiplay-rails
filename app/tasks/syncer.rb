class Syncer
  include Sidekiq::Worker

  @queue = :high # is this even a thing with sidekiq or a carryover from my old resque code?

  def perform
    errors = []

    User.all.each do |user|
      playlists = user.google_playlists.to_sync
      next if playlists.empty?

      puts "processing user #{user.id}"
      puts 'loading google play data'

      # load playlist entries for user
      response = user.play.get('playlist_entries')
      unorganized_entries = response['entries']

      playlists_to_entries = {} # playlists to arrays of their entries

      all_tracks_response = user.play.get('all_tracks')
      all_tracks = all_tracks_response['entries']

      puts 'done loading play data'

      unorganized_entries.each do |entry|
        playlist_id = entry['playlistId']
        playlist = playlists.find_by(google_id: playlist_id)

        if entry['track'].nil?
          entry['track'] = all_tracks.find { |track| track['id'] == entry['trackId'] }
          next if entry['track'].nil?
        end

        next if playlist.nil? # not sure, but we're dealing with an undocumented API here so let's just be safe...

        playlists_to_entries[playlist] ||= []
        playlists_to_entries[playlist] << entry
      end

      puts 'done prepping playlist metadata for sync'

      # all entries should have a track object with metadata now :D

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
    puts "syncing playlist #{playlist.name}"
    if playlist.spotify_playlist.nil?
      rspotify_playlist = playlist.user.rspotify.create_playlist!(playlist.name)
      playlist.spotify_playlist = playlist.user.spotify_playlists.create!(
          name: rspotify_playlist.name,
          spotify_id: rspotify_playlist.id
      )
      playlist.save!
      puts 'made spotify playlist'
    end

    raise if playlist.spotify_playlist.nil?

    # sync tracks
    rspotify_tracks = entries.map do |entry|
      find_track_on_spotify(entry['track'])
    end

    puts "found tracks: #{rspotify_tracks.map(&:name)}"

    playlist.spotify_playlist.rspotify.add_tracks!(rspotify_tracks)
    puts 'added to spotify playlist'

    return nil
  rescue => e
    return e
  end

  def find_track_on_spotify(track)
    raise if track.nil?
    # TODO: better algorithm
    RSpotify::Track.search("#{track['title']} #{track['artist']}").first
  end
end

# schedule this job once a minute
Sidekiq::Cron::Job.create(
    name: 'Syncer: syncs google play playlists to spotify',
    cron: '* * * * *',
    class: 'Syncer'
)