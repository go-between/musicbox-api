module Mutations
  class CreateRoomQueue < Mutations::BaseMutation
    argument :order, Int, required: true
    argument :room_id, ID, required: true
    argument :song_id, ID, required: true

    field :room_queue, Types::RoomQueueType, null: true
    field :errors, [String], null: true

    def resolve(order:, room_id:, song_id:)
      room_queue = RoomQueue.new(order: order, room_id: room_id, song_id: song_id, user: context[:current_user])
      if room_queue.save
        queue = MusicboxApiSchema.execute(query: query, variables: { roomId: room_queue.room_id })
        QueuesChannel.broadcast_to(room_queue.room, queue.to_h)
        # ActionCable.server.broadcast('now_playing', enqueued_songs(room_queue).map(&:attributes))

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

    def query
      %(
        query($roomId: ID!) {
          roomQueues(roomId: $roomId) {
            id, order, song { id, name }, user { email }
          }
        }
      )
    end
  end
end
