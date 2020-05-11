# frozen_string_literal: true

class QueueManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: "queue_management"

  def perform(room_id)
    room = Room.find(room_id)
    return unless update_room!(room)

    BroadcastTeamWorker.perform_async(room.team_id)
    BroadcastNowPlayingWorker.perform_async(room_id)
    BroadcastPlaylistWorker.perform_async(room_id)
  end

  private

  def update_room!(room)
    room.with_lock do
      return unless room.queue_processing?
      return if room.playing_until&.future?

      next_record = next_record_in_playlist(room)
      remove_stale_user_from_room!(room)

      if next_record.blank?
        room.idle!
        return true
      end

      next_record.update!(play_state: "played", played_at: Time.zone.now)
      room.playing_record!(next_record)

      return true
    end
  end

  def next_record_in_playlist(room)
    relation = RoomPlaylistRecord.includes(:song, :user)
    RoomPlaylistGenerator.new(room, relation).playlist.first
  end

  def remove_stale_user_from_room!(room)
    return if room.current_record.blank?

    user = room.current_record.user
    return if user.active_room_id == room.id
    return if RoomPlaylistRecord.waiting.where(user_id: user.id).exists?

    room.update!(user_rotation: room.user_rotation.without(user.id))
  end
end
