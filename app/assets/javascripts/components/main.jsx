var Main = React.createClass({
    getInitialState() {
        return {
            play_playlists: []
        }
    },

    componentDidMount() {
        this.reloadPlaylists();
    },

    reloadPlaylists() {
        $.get('/google_playlists', response => {
            this.setState({play_playlists: response.playlists});
        });
    },

    render() {
        return <div>
            <h1>Spotiplay</h1>
            <PlaylistList
                onPlaylistReload={this.reloadPlaylists}
                playlists={this.state.play_playlists}/>
        </div>
    }
});

var PlaylistList = React.createClass({
    render() {
        let playlistItems = this.props.playlists.map(playlist => {
            return <PlaylistItem
                onPlaylistReload={this.props.onPlaylistReload}
                key={playlist.id}
                playlist={playlist}/>
        });
        return <div>{playlistItems}</div>
    }
});

var PlaylistItem = React.createClass({
    changedShouldSync(event) {
        let shouldSync = event.target.checked;

        this.props.playlist.should_sync = shouldSync;
        this.forceUpdate();

        $.ajax(`/google_playlists/${this.props.playlist.id}`, {
            method: 'patch',
            data: {
                google_playlist: {
                    should_sync: shouldSync
                }
            },
            success: result => {
                this.props.onPlaylistReload();
            },
            error: result => {
                this.props.onPlaylistReload();
            }
        })
    },

    render() {
        return <div>
            <strong>{this.props.playlist.name}</strong>
            <input type="checkbox" checked={this.props.playlist.should_sync} onChange={this.changedShouldSync}/>
        </div>
    }
});