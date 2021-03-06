# frozen_string_literal: true

class BroadcastPlaylistWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_playlist"

  def perform(room_id)
    queue = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { roomId: room_id }
    )
    RoomPlaylistChannel.broadcast_to(Room.find(room_id), queue.to_h)
  end

  private

  def query
    %(
      query BroadcastPlaylistWorker($roomId: ID!) {
        roomPlaylist(roomId: $roomId) {
          id, order, song { id, durationInSeconds, name, thumbnailUrl, youtubeId }, user { id, email, name }
        }
      }
    )
  end
end
