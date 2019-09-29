class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'queue_management'

  def perform(room_id)
    playlist = RoomPlaylist.new(room_id).generate_playlist

    next_record = playlist[0]
    return empty_queue!(room_id) if next_record.blank?

    next_record.update!(play_state: "played", played_at: Time.zone.now)

    Room.find(room_id).update!(current_record: next_record)

    BroadcastNowPlayingWorker.perform_async(room_id)
    BroadcastPlaylistWorker.perform_async(room_id)
    self.class.perform_in(next_record.song.duration_in_seconds, room_id)
  end

  private

  def empty_queue!(room_id)
    room = Room.find(room_id)

    if room.current_record.present?
      room.update!(current_record: nil)

      BroadcastNowPlayingWorker.perform_async(room_id)
      BroadcastPlaylistWorker.perform_async(room_id)
    end

    self.class.perform_in(1.second, room_id)
  end
end
