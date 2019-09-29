# frozen_string_literal: true

class BroadcastUsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'websocket_broadcast'

  def perform(room_id)
    queue = MusicboxApiSchema.execute(query: query, variables: { id: room_id })
    UsersChannel.broadcast_to(Room.find(room_id), queue.to_h)
  end

  private

  def query
    %(
      query($id: ID!) {
        room(id: $id) {
          users { id, email }
        }
      }
    )
  end
end
