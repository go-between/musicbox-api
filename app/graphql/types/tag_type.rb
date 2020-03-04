# frozen_string_literal: true

module Types
  class TagType < Types::BaseObject
    graphql_name "Tag"

    field :id, ID, null: false
    field :name, String, null: false
    field :user, Types::UserType, null: false
    field :songs, [Types::SongType], null: false
  end
end
