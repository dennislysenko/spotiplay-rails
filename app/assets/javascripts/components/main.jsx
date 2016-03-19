var Main = React.createClass({
    getInitialState() {
        return {
            play_playlists: []
        }
    },

    componentDidMount() {
        $.get('/play_test', response => {
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
        let playlistItems = this.props.playlists.map(playlist => <PlaylistItem playlist={playlist}/>);
        return <div>{playlistItems}</div>
    }
});

var PlaylistItem = React.createClass({
    render() {
        return <div key={this.props.playlist.id}>{this.props.playlist.name}</div>
    }
});