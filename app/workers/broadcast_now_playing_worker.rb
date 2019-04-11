class BroadcastNowPlayingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'websocket_broadcast'

  def perform(room_id)
    now_playing = MusicboxApiSchema.execute(query: query, variables: { id: up_next.song_id })
    NowPlayingChannel.broadcast_to(up_next.room, now_playing.to_h)
    self.class.perform_in(now_playing.dig(:data, :song, :durationInSeconds).seconds, room_id)
  end

  private

  def query
    %(
      query($id: ID!) {
        song(id: $id) {
          id, description, durationInSeconds, name, youtubeId
        }
      }
    )
  end
end
