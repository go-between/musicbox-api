module Types
  class MutationType < Types::BaseObject
    field :create_song, mutation: Mutations::CreateSong

    field :delete_room_playlist_record, mutation: Mutations::DeleteRoomPlaylistRecord
    field :delete_song_user, mutation: Mutations::DeleteSongUser

    field :join_room, mutation: Mutations::JoinRoom
    field :order_room_songs, mutation: Mutations::OrderRoomSongs
  end
end
