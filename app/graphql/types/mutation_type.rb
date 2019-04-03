module Types
  class MutationType < Types::BaseObject
    field :create_room_queue, mutation: Mutations::CreateRoomQueue
    field :create_song, mutation: Mutations::CreateSong
    field :join_room, mutation: Mutations::JoinRoom
  end
end
