module Types
  class MutationType < Types::BaseObject
    field :create_song, mutation: Mutations::CreateSong

    field :delete_room_playlist_record, mutation: Mutations::DeleteRoomPlaylistRecord
    field :delete_user_library_record, mutation: Mutations::DeleteUserLibraryRecord

    field :join_room, mutation: Mutations::JoinRoom
    field :order_room_playlist_records, mutation: Mutations::OrderRoomPlaylistRecords
  end
end
