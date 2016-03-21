Rails.application.routes.draw do
  root 'welcome#index'

  resources :google_playlists, only: [:index, :update]

  # misc
  get 'spotify/playlists'
  get 'spotify_test', to: 'welcome#spotify_test'
  get 'play_test', to: 'welcome#play_test'

  # auth
  get 'spotify_callback', to: 'users#spotify_callback'
  resources :users do
    get 'login_spotify', on: :collection
    post 'authenticate_google', on: :collection
  end

  mount Sidekiq::Web => '/admin/sidekiq'
end
