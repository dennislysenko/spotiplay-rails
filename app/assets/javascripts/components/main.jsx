var Main = React.createClass({
    getInitialState() {
        return {
            play_playlists: []
        }
    },

    componentDidMount() {
        $.get('/play/playlists', response => {
            this.setState({play_playlists: response.playlists});
        });
    },

    render() {
        return <div>
            <h1>Spotiplay</h1>
            <PlaylistList playlists={this.state.play_playlists}/>
        </div>
    }
});

var PlaylistList = React.createClass({
    render() {
        let playlistItems = this.props.playlists.map(playlist => <PlaylistItem key={this.props.playlist.id} playlist={playlist}/>);
        return <div>{playlistItems}</div>
    }
});

var PlaylistItem = React.createClass({
    render() {
        return <div>{this.props.playlist.name}</div>
    }
});