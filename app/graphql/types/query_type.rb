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
      argument :historical, Boolean, required: false
    end

    def room_songs(room_id:, for_user: false, historical: false)
      unless for_user || historical
        RoomSongDisplayer.new(room_id).waiting
      else
        songs = RoomSong.where(room_id: room_id)
        songs = songs.where(user: context[:current_user]) if for_user
        if historical
          songs.where(play_state: "finished").order(played_at: :desc)
        else
          songs.where(play_state: "waiting").order(:order)
        end
      end
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
