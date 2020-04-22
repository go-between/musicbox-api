# frozen_string_literal: true

class BroadcastPinnedMessagesWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_pinned_messages"

  def perform(room_id, song_id)
    queue = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { roomId: room_id, songId: song_id }
    )
    PinnedMessagesChannel.broadcast_to(Room.find(room_id), queue.to_h)
  end

  private

  def query # rubocop:disable Metrics/MethodLength
    %(
      query BroadcastPinnedMessages($roomId: ID, $songId: ID!) {
        pinnedMessages(roomId: $roomId, songId: $songId) {
          id
          createdAt
          message
          pinned
          roomPlaylistRecord {
            id
            playedAt
          }
          song {
            name
          }
          user {
            id
            email
            name
          }
        }
      }
    )
  end
end
