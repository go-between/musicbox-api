class BroadcastNowPlayingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'websocket_broadcast'

  def perform(room_id)
    now_playing = MusicboxApiSchema.execute(query: query, variables: { id: room_id })

    NowPlayingChannel.broadcast_to(Room.find(room_id), now_playing.to_h)
  end

  private

  def query
    %(
      query($id: ID!) {
        room(id: $id) {
          currentSong { id, description, durationInSeconds, name, youtubeId },
          currentRecord { playedAt }
        }
      }
    )
  end
end
