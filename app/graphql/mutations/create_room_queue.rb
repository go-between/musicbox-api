module Mutations
  class CreateRoomQueue < Mutations::BaseMutation
    argument :order, String, required: true
    argument :room_id, String, required: true
    argument :song_id, String, required: true
    argument :user_id, String, required: true

    field :room_queue, Types::RoomQueueType, null: true
    field :errors, [String], null: true

    def resolve(order:, room_id:, song_id:, user_id:)
      room_queue = RoomQueue.new(order: order, room_id: room_id, song_id: song_id, user_id: user_id)
      if room_queue.save
        ActionCable.server.broadcast('queue', enqueued_songs(room_queue).map(&:attributes))
        ActionCable.server.broadcast('now_playing', enqueued_songs(room_queue).map(&:attributes))

        {
          room_queue: room_queue,
          errors: [],
        }
      else
        {
          room_queue: nil,
          errors: room_queue.errors.full_messages
        }
      end
    end

    private

    def enqueued_songs(room_queue)
      room_queue.room.enqueued_songs
    end
  end
end
