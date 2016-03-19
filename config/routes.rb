Rails.application.routes.draw do
  get 'google/playlists'
  get 'spotify/playlists'

  root 'welcome#index'
  # get '/auth/spotify/callback', to: 'users#authenticate_spotify'
  # get 'users/authenticate_google'
  get 'spotify_callback', to: 'users#spotify_callback'
  get 'spotify_test', to: 'welcome#spotify_test'
  get 'play_test', to: 'welcome#play_test'
  resources :users do
    get 'login_spotify', on: :collection
    get 'authenticate_spotify', on: :collection
    post 'authenticate_google', on: :collection
  end
end
