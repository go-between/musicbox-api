# frozen_string_literal: true

class BroadcastNowPlayingWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_now_playing"

  def perform(room_id)
    now_playing = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { id: room_id }
    )

    logger.debug("Preparing to broadcast to room #{room_id}")
    logger.debug("With song #{now_playing.to_h}")

    NowPlayingChannel.broadcast_to(Room.find(room_id), now_playing.to_h)
  end

  private

  def query # rubocop:disable Metrics/MethodLength
    %(
      query BroadcastNowPlayingWorker($id: ID!) {
        room(id: $id) {
          currentRecord {
            id
            playedAt
            song {
              id
              name
              youtubeId
            }
            user {
              name
              email
            }
          }
        }
      }
    )
  end
end
