class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'queue_management'

  def perform(room_id)
    displayer = RoomSongDisplayer.new(room_id)

    just_finished = displayer.now_playing
    just_finished.update!(play_state: "finished") if just_finished.present?

    next_queued_song = displayer.up_next
    return empty_queue!(room_id) if next_queued_song.blank?

    next_queued_song.update!(play_state: "playing")

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
