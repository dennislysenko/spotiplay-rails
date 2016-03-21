class Syncer
  include Sidekiq::Worker

  attr_accessor :draft_mode

  def draft_mode?
    draft_mode
  end

  # syncs all google and spotify playlists in the library with each other.
  # if draft_mode is true, will do a "dress rehearsal" runthrough of the sync process without modifying anything.
  def perform(draft_mode=false)
    self.draft_mode = draft_mode
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
    # quickly just make sure the user is authed on rspotify
    playlist.user.rspotify

    # first ensure a companion spotify playlist exists
    # TODO: make this treat a spotify playlist with the same name as a companion playlist automatically
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

    # all_tracks defined below
    updated_spotify_tracks = playlist.spotify_playlist.rspotify.all_tracks

    # now check for changes from the last time we synced both the google and spotify playlists
    updated_google_track_ids = Set.new(entries.map { |entry| entry['track']['id'] })
    old_google_track_ids = Set.new(playlist.google_tracks.map(&:google_id))
    updated_spotify_track_ids = Set.new(updated_spotify_tracks.map(&:id))
    old_spotify_track_ids = Set.new(playlist.spotify_playlist.spotify_tracks.map(&:spotify_id))

    added_google_track_ids = updated_google_track_ids - old_google_track_ids
    removed_google_track_ids = old_google_track_ids - updated_google_track_ids
    added_spotify_track_ids = updated_spotify_track_ids - old_spotify_track_ids
    removed_spotify_track_ids = old_spotify_track_ids - updated_spotify_track_ids

    # process tracks that were removed from the google playlist
    tracks_to_remove_from_spotify = []
    # implied that removed_google_track was in playlist.google_tracks before
    removed_google_tracks = removed_google_track_ids.map { |id| playlist.google_tracks.find_by(google_id: id) }.compact
    removed_google_tracks.each do |google_track|
      if google_track.spotify_track.present?
        tracks_to_remove_from_spotify << google_track.spotify_track.spotify_json['uri']
      else
        warn "weird, removed google track #{google_track} had no spotify track"
      end
    end
    if draft_mode?
      puts "google tracks were detected as removed: #{removed_google_tracks.map(&:title)}"
      puts "with companion spotify tracks #{tracks_to_remove_from_spotify}"
    else
      playlist.spotify_playlist.rspotify.remove_tracks_by_uri! tracks_to_remove_from_spotify
      removed_google_tracks.map(&:spotify_track).compact.each(&:destroy!)
      removed_google_tracks.each(&:destroy!)
    end

    # process tracks that were removed from the spotify playlist
    # (implied that these track were in spotify_playlist.spotify_tracks before)
    entry_ids_to_remove = []
    removed_spotify_tracks = removed_spotify_track_ids.map do |removed_spotify_track_id|
      playlist.spotify_playlist.spotify_tracks.find_by(spotify_id: removed_spotify_track_id)
    end.compact # note the .compact here!
    removed_spotify_tracks.each do |spotify_track|
      if spotify_track.google_track.present?
        entry_ids_to_remove << spotify_track.google_track.google_entry_id
      else
        warn "weird, removed spotify track #{spotify_track} had no google track"
      end
    end
    unless entry_ids_to_remove.empty?
      if draft_mode?
        puts "spotify tracks were detected as removed: #{removed_spotify_tracks.map(&:title)}"
        puts "with google play entry ids #{entry_ids_to_remove}"
      else
        result = playlist.user.play.post('remove_entries', entry_ids: entry_ids_to_remove.join(','))
        if result['success']
          p result
          removed_spotify_tracks.map(&:google_track).compact.each(&:destroy!)
          removed_spotify_tracks.each(&:destroy!)
        else
          raise "weird, couldn't remove play tracks. leaving them as-is. response was #{result}"
        end
      end
    end

    # process tracks that were added to the google playlist.
    tracks_to_add_to_spotify = []
    # added_google_track_ids were all in entries before :D
    added_google_entries = added_google_track_ids.map { |id| entries.find { |entry| entry['track']['id'] == id } }
    added_google_entries.each do |entry|
      title = entry['track']['title']
      artist = entry['track']['artist']
      album = entry['track']['album']

      spotify_track = find_track_on_spotify(title, artist, album)

      if spotify_track.nil?
        warn "couldn't find match for google track #{title} by #{artist} (from #{album})"
      else
        tracks_to_add_to_spotify << spotify_track
        create_mirrored_track!(playlist, entry, spotify_track) unless draft_mode?
      end
    end
    unless tracks_to_add_to_spotify.empty?
      if draft_mode?
        puts "detected added google tracks: #{added_google_entries.map { |entry| entry['track']['title'] }}"
      else
        playlist.spotify_playlist.rspotify.add_tracks!(tracks_to_add_to_spotify)
        puts 'added to spotify playlist'
      end
    end

    # process tracks that were added to the spotify playlist.
    added_spotify_tracks = added_spotify_track_ids.map { |id| updated_spotify_tracks.find { |track| track.id == id } }
    play_track_ids_to_add = []
    added_google_tracks = []
    added_spotify_tracks.each do |track|
      entry = find_track_on_play(track.name, track.artists.map(&:name).join(' '), track.album.name, playlist)

      if entry.nil?
        warn "couldn't find match for spotify track #{track.name} by #{track.artists}"
      else
        play_track_ids_to_add << entry['track']['storeId']
        added_google_tracks << create_mirrored_track!(playlist, entry, track) unless draft_mode?
      end
    end
    unless play_track_ids_to_add.empty?
      if draft_mode?
        puts "detected added spotify tracks: #{added_spotify_tracks.map(&:name)}"
      else
        response = playlist.user.play.post('add_entries', playlist_id: playlist.google_id, track_ids: play_track_ids_to_add.join(','))
        if response['success']
          response['body']['mutate_response'].each.with_index do |result, index|
            google_track = added_google_tracks[index]
            next if google_track.nil?

            if result['response_code'] == 'OK'
              google_track.update!(google_entry_id: result['id'])
            else
              warn "unsuccessful result #{result} from adding track to playlist. track was #{google_track}; removing the local google track"
              google_track.spotify_track.try(:destroy!)
              google_track.destroy!
            end
          end
        else
          raise "weird, couldn't add play tracks. leaving them as-is. response was #{response}"
        end
      end
    end

    return nil
  rescue => e
    return e
  end


  def find_track_on_spotify(title, artist, album)
    # TODO: better algorithm
    RSpotify::Track.search("#{title} #{artist}").first
  end

  def find_track_on_play(title, artist, album, playlist)
    response = playlist.user.play.post('search', query: "#{title} #{artist}")
    results = response['results'].select { |result| result['type'].to_i == 1 }
    results.first
  end

  def create_mirrored_track!(playlist, google_entry, spotify_track)
    ActiveRecord::Base.transaction do
      google_track = playlist.google_tracks.create(
          google_json: google_entry,
          google_entry_id: google_entry['id'],
          google_id: google_entry['track']['id'],
          title: google_entry['track']['title'],
          artist: google_entry['track']['artist'],
          album: google_entry['track']['album'],
          duration_ms: google_entry['track']['durationMillis'].to_i,
      )

      spotify_track = playlist.spotify_playlist.spotify_tracks.create(
          spotify_json: spotify_track.as_json,
          spotify_id: spotify_track.id,
          title: spotify_track.name,
          artist: spotify_track.artists.map(&:name).join(', '),
          album: spotify_track.album.name,
          duration_ms: spotify_track.duration_ms,
      )

      google_track.spotify_track = spotify_track
      google_track.save!

      google_track
    end
  end
end

module RSpotify
  class Playlist
    TRACKS_AT_A_TIME = 100

    def all_tracks
      all_tracks = []
      offset = 0
      loop do
        iter_tracks = tracks(limit: TRACKS_AT_A_TIME, offset: offset)
        all_tracks.concat(iter_tracks)

        if iter_tracks.count == TRACKS_AT_A_TIME
          offset += TRACKS_AT_A_TIME
          # got 100 tracks so almost definitely another page of tracks, let's go get more
        else
          # less than 100 tracks means last page probably, so leave the loop
          break
        end
      end

      all_tracks
    end

    def remove_tracks_by_uri!(track_uris)
      tracks = track_uris.map { |uri| { uri: uri } }

      params = {
          method: :delete,
          url: URI::encode(RSpotify::API_URI + @path + '/tracks'),
          headers: User.send(:oauth_header, @owner.id),
          payload: { tracks: tracks }
      }

      params[:payload] = params[:payload].to_json
      response = RestClient::Request.execute(params)

      @snapshot_id = JSON.parse(response)['snapshot_id']
      @tracks_cache = nil
      self
    end
  end
end

# schedule this job once a minute
Sidekiq::Cron::Job.create(
    name: 'Syncer: syncs google play playlists to spotify',
    cron: '* * * * *',
    class: 'Syncer'
)