Rails.application.routes.draw do

  mount ActionCable.server => '/cable'

  scope path: '/api' do
    resources :docs, only: [:index], path: '/swagger'

    scope path: '/v1' do
      post "/graphql", to: "graphql#execute"

      devise_for :users
      use_doorkeeper

      resources :users
      resources :rooms, only: [:show]
      resources :room_queues, only: [:create]
      resources :songs, only: [:create]
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
