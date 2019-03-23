module Types
  class RoomQueueType < Types::BaseObject
    graphql_name 'RoomQueue'

    field :id, ID, null: false
    field :order, Int, null: false
    field :room, Types::RoomType, null: false
    field :song, Types::SongType, null: false
    field :user, Types::UserType, null: false
  end
end
