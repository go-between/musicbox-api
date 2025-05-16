# frozen_string_literal: true

module Types
  class TeamType < Types::BaseObject
    graphql_name "Team"

    field :id, ID, null: false
    field :name, String, null: true
    field :rooms, [ Types::RoomType ], null: false
    field :users, [ Types::UserType ], null: false
  end
end
