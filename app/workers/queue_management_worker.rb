class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'queue_management'

  def perform(room_id)
    queue = RoomQueue.where(room_id: room_id)
    return self.class.perform_in(1.second, room_id) if queue.empty?
    up_next = queue.first
    Room.find(room_id).update!(current_song_id: up_next.song_id, current_song_start: Time.zone.now)
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
