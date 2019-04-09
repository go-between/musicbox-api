module Types
  class RoomSongType < Types::BaseObject
    graphql_name 'RoomSong'

    field :id, ID, null: false
    field :order, Int, null: false
    field :room, Types::RoomType, null: false
    field :song, Types::SongType, null: false
    field :user, Types::UserType, null: false
  end
end
