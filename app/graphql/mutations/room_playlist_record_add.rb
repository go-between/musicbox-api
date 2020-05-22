# frozen_string_literal: true

module Mutations
  class RoomPlaylistRecordAdd < Mutations::BaseMutation
    argument :id, ID, required: true

    field :errors, [String], null: true

    def resolve(id:)
      room = Room.find(current_user.active_room_id)
      return { errors: ["Not in active room"] } if room.blank?

      room.with_lock do
        ensure_user_in_rotation!(room)
        # Note:  We may actually be removing the last song from the room
        #        in this call, but we'll allow the queue management
        #        worker to clean that up.
        room.update!(waiting_songs: true) unless room.waiting_songs

        RoomPlaylistRecord.create!(
          room_id: room.id,
          song_id: id,
          user: current_user,
          play_state: :waiting,
          order: order_for_new_record_in(room)
        )
      end

      BroadcastPlaylistWorker.perform_async(room.id)
      { errors: [] }
    end

    private

    def ensure_user_in_rotation!(room)
      return if room.user_rotation.include?(current_user.id)

      rotation = room.user_rotation << current_user.id
      room.update!(user_rotation: rotation)
    end

    def order_for_new_record_in(room)
      record = latest_record(room)
      return record.order + 1 if record.present?

      0
    end

    def latest_record(room)
      RoomPlaylistRecord
        .waiting
        .where(room: room, user: current_user)
        .select(:order)
        .order(order: :desc)
        .first
    end
  end
end
