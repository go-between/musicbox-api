# frozen_string_literal: true

class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: "queue_management"

  def perform(room_id)
    room = Room.find(room_id)

    update_room!(room) do
      BroadcastNowPlayingWorker.perform_async(room_id)
      BroadcastPlaylistWorker.perform_async(room_id)
    end
  end

  private

  def update_room!(room)
    room.with_lock do
      return if room.playing_until&.future?

      next_record = RoomPlaylist.new(room.id).generate_playlist.first
      return idle!(room) && yield if next_record.blank?

      next_record.update!(play_state: "played", played_at: Time.zone.now)
      room.update!(current_record: next_record, playing_until: playing_until(next_record))

      yield
    end
  end

  def playing_until(record)
    record.song.duration_in_seconds.seconds.from_now
  end

  def idle!(room)
    room.update!(current_record: nil, playing_until: nil, waiting_songs: false)
  end
end
