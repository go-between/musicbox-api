module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :room, Types::RoomType, null: true do
      argument :id, ID, required: true
    end

    def room(id:)
      Room.find(id)
    end

    field :rooms, [Types::RoomType], null: true do
    end

    def rooms
      Room.all
    end

    field :room_songs, [Types::RoomSongType], null: true do
      argument :room_id, ID, required: true
      argument :for_user, Boolean, required: false
    end

    def room_songs(room_id:, for_user:)
      # TODO:  Service class to determine real order
      songs = RoomSong.where(room_id: room_id)
      songs = songs.where(user: context[:current_user]) if for_user

      songs.interleaved_by_oldest_user
    end

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

    field :users, [Types::UserType], null: true do
    end

    def users
      User.all
    end
  end
end
