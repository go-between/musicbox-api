module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :songs, [Types::SongType], null: true do
    end

    def songs
      context[:current_user].songs
    end

    field :room_queues, [Types::RoomQueueType], null: true do
      argument :room_id, ID, required: true
    end

    def room_queues(room_id:)
      # TODO:  Service class to determine real order
      RoomQueue.where(room_id: room_id)
    end

    field :users, [Types::UserType], null: true do
    end

    def users
      User.all
    end
  end
end
