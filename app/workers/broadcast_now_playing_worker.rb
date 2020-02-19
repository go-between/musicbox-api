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

    NowPlayingChannel.broadcast_to(Room.find(room_id), now_playing.to_h)
  end

  private

  def query
    %(
      query($id: ID!) {
        room(id: $id) {
          currentRecord {
            id
            playedAt
            song {
              name
              youtubeId
            }
          }
        }
      }
    )
  end
end
