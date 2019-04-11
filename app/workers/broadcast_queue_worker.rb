class BroadcastQueueWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'websocket_broadcast'

  def perform(room_id)
    queue = MusicboxApiSchema.execute(query: query, variables: { roomId: room_id })
    QueuesChannel.broadcast_to(Room.find(room_id), queue.to_h)
  end

  private

  def query
    %(
      query($roomId: ID!) {
        roomSongs(roomId: $roomId) {
          id, order, song { id, name }, user { email }
        }
      }
    )
  end
end
