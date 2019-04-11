class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'queue_management'

  def perform(room_id)
    queue = RoomSong.where(room_id: room_id)
    return empty_queue!(room_id) if queue.empty?

    queue_entry = queue.first
    next_queued_song = queue_entry.song
    queue_entry.destroy!

    Room.find(room_id).update!(current_song_id: next_queued_song.id, current_song_start: Time.zone.now)

    BroadcastNowPlayingWorker.perform_async(room_id)
    BroadcastQueueWorker.perform_async(room_id)
    self.class.perform_in(next_queued_song.duration_in_seconds, room_id)
  end

  private

  def empty_queue!(room_id)
    room = Room.find(room_id)

    if room.current_song.present?
      room.update!(current_song: nil, current_song_start: nil)

      BroadcastNowPlayingWorker.perform_async(room_id)
      BroadcastQueueWorker.perform_async(room_id)
    end

    self.class.perform_in(1.second, room_id)
  end
end
