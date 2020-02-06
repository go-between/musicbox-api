# frozen_string_literal: true

class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: "queue_management"

  def perform(room_id) # rubocop:disable Metrics/AbcSize
    room = Room.find(room_id)
    room.with_lock do
      return if room.playing_until&.future?

      playlist = RoomPlaylist.new(room_id).generate_playlist

      next_record = playlist.first
      return idle!(room) if next_record.blank?

      next_record.update!(play_state: "played", played_at: Time.zone.now)
      playing_until = next_record.song.duration_in_seconds.seconds.from_now
      room.update!(current_record: next_record, playing_until: playing_until)

      BroadcastNowPlayingWorker.perform_async(room_id)
      BroadcastPlaylistWorker.perform_async(room_id)
    end
  end

  private

  def idle!(room)
    just_finished = room.current_record.present?
    room.update!(current_record: nil, playing_until: nil, waiting_songs: false)

    return unless just_finished

    BroadcastNowPlayingWorker.perform_async(room.id)
    BroadcastPlaylistWorker.perform_async(room.id)
  end
end
