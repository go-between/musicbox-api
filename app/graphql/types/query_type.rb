module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :songs, [Types::SongType], null: true do
    end

    field :room_queues, [Types::RoomQueueType], null: true do
      argument :room_id, ID, required: true
    end

    field :users, [Types::UserType], null: true do
    end

    def room_queues(room_id:)
      RoomQueue.where(room_id: room_id)
    end

    def songs
      context[:current_user].songs
    end

    def users
      User.all
    end
  end
end
