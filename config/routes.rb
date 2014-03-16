Twitchquotes::Application.routes.draw do
  # resources :users
  resources :quotes
  resources :sessions, only: [:new, :create, :destroy]
  resources :streams, only: [:index, :show]
  resources :announcements, only: [:create, :update, :edit]
  resources :likes, only: [:create, :destroy]
  resources :dislikes, only: [:create, :destroy]

  root to: 'quotes#index'
  get "api_search_streams", to: 'streams#search'
  get '/help', to: 'static_pages#help'
  get '/about', to: 'static_pages#about'
  get '/signin', to: 'sessions#new'
  get '/admin', to: 'users#admin'
  delete '/signout', to: 'sessions#destroy'

  get 'auth/:provider/callback', to: 'facebook_sessions#create'
  post 'auth/:provider/callback', to: 'facebook_sessions#create'
  get 'auth/failure', to: redirect('/')
  post 'auth/failure', to: redirect('/')
  get 'facebook/signout', to: 'facebook_sessions#destroy', as: 'facebook_signout'
end