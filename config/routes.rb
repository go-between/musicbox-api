# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/workers'
  mount ActionCable.server => '/cable'
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/v1/graphql'

  scope path: '/api' do
    scope path: '/v1' do
      post '/graphql', to: 'graphql#execute'
      use_doorkeeper
    end
  end
end
