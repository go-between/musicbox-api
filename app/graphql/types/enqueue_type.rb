module Types
  class EnqueueType < Types::BaseObject
    graphql_name 'Enqueue'

    field :order, Int, null: false
    field :song, Types::SongType, null: false
    field :user, Types::UserType, null: false
    field :room, Types::RoomType, null: false
  end
end
