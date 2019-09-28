module Types
  class MutationType < Types::BaseObject
    field :create_song, mutation: Mutations::CreateSong
    field :join_room, mutation: Mutations::JoinRoom
    field :order_room_songs, mutation: Mutations::OrderRoomSongs
    field :delete_room_song, mutation: Mutations::DeleteRoomSong
    field :delete_song_user, mutation: Mutations::DeleteSongUser
  end
end
