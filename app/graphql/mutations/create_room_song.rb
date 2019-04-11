module Mutations
  class CreateRoomSong < Mutations::BaseMutation
    argument :order, Int, required: true
    argument :room_id, ID, required: true
    argument :song_id, ID, required: true

    field :room_song, Types::RoomSongType, null: true
    field :errors, [String], null: true

    def resolve(order:, room_id:, song_id:)
      room_song = RoomSong.new(order: order, room_id: room_id, song_id: song_id, user: context[:current_user])
      if room_song.save
        BroadcastQueueWorker.perform_async(room_id)

        {
          room_song: room_song,
          errors: [],
        }
      else
        {
          room_song: nil,
          errors: room_song.errors.full_messages
        }
      end
    end
  end
end
