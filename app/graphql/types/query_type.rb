module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :song, Types::SongType, null: true do
      argument :id, ID, required: true
    end

    def song(id:)
      Song.find(id)
    end

    field :songs, [Types::SongType], null: true do
    end

    def songs
      context[:current_user].songs
    end

    field :room_songs, [Types::RoomSongType], null: true do
      argument :room_id, ID, required: true
    end

    def room_songs(room_id:)
      # TODO:  Service class to determine real order
      RoomSong.where(room_id: room_id)
    end

    field :users, [Types::UserType], null: true do
    end

    def users
      User.all
    end
  end
end
