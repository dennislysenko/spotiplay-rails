Rails.application.routes.draw do
  get 'welcome/index'

  root 'welcome#index'
  get '/auth/facebook/callback', to: 'users#authenticate'
end
