# frozen_string_literal: true

module Types
  class YoutubeResultType < Types::BaseObject
    graphql_name "YoutubeResult"

    field :id, ID, null: false
    field :description, String, null: false
    field :duration, Integer, null: false
    field :title, String, null: false
    field :thumbnail_url, String, null: false
  end
end
