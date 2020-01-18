# frozen_string_literal: true

module Types
  class SongType < Types::BaseObject
    graphql_name "Song"

    field :id, ID, null: false
    field :description, String, null: true
    field :duration_in_seconds, Int, null: true
    field :name, String, null: true
    field :youtube_id, ID, null: false
  end
end
