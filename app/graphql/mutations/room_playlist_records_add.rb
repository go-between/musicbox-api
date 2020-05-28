# frozen_string_literal: true

module Mutations
  class RoomPlaylistRecordsAdd < Mutations::BaseMutation
    argument :ids, [ID], required: true

    field :errors, [String], null: true

    def resolve(ids:)
      room = Room.find(current_user.active_room_id)
      return { errors: ["Not in active room"] } if room.blank?

      room.with_lock do
        ensure_user_in_rotation!(room)
        # Note:  We may actually be removing the last song from the room
        #        in this call, but we'll allow the queue management
        #        worker to clean that up.
        room.update!(waiting_songs: true) unless room.waiting_songs
        add_records!(ids, room)
      end

      BroadcastPlaylistWorker.perform_async(room.id)
      { errors: [] }
    end

    private

    def add_records!(song_ids, room)
      starting_order = starting_order_for_new_records_in(room)
      song_ids.each.with_index do |song_id, idx|
        LibraryRecord.find_or_create_by!(song_id: song_id, user: current_user)
        RoomPlaylistRecord.create!(
          room_id: room.id,
          song_id: song_id,
          user: current_user,
          play_state: :waiting,
          order: starting_order + idx
        )
      end
    end

    def ensure_user_in_rotation!(room)
      return if room.user_rotation.include?(current_user.id)

      rotation = room.user_rotation << current_user.id
      room.update!(user_rotation: rotation)
    end

    def starting_order_for_new_records_in(room)
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
