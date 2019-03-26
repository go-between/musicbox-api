module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :songs, [Types::SongType], null: true do
    end

    field :room_queues, [Types::RoomQueueType], null: true do
    end

    def room_queues
      RoomQueue.all
    end

    def songs
      Song.all
    end
  end
end
