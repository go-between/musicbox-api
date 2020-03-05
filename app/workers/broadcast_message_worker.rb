# frozen_string_literal: true

class BroadcastMessageWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_message"

  def perform(room_id, message_id)
    queue = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { id: message_id }
    )
    MessageChannel.broadcast_to(Room.find(room_id), queue.to_h)
  end

  private

  def query # rubocop:disable Metrics/MethodLength
    %(
      query BroadcastMessageWorker($id: ID!) {
        message(id: $id) {
          id
          message
          pinned
          createdAt
          song {
            name
          }
          user {
            email
            name
          }
        }
      }
    )
  end
end
