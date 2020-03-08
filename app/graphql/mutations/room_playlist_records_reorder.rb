# frozen_string_literal: true

module Mutations
  class RoomPlaylistRecordsReorder < Mutations::BaseMutation
    class OrderedPlaylistRecordInputObject < Types::BaseInputObject
      argument :room_playlist_record_id, ID, required: false
      argument :song_id, ID, required: true
    end

    argument :ordered_records, [OrderedPlaylistRecordInputObject], required: true

    field :room_playlist_records, [Types::RoomPlaylistRecordType], null: true
    field :errors, [String], null: true

    def resolve(ordered_records:)
      room = Room.find(current_user.active_room_id)
      return { errors: ["Not in active room"] } if room.blank?

      existing_record_ids = ordered_records.map { |r| r[:room_playlist_record_id] }.compact
      records = update_records!(room, ordered_records, existing_record_ids)
      BroadcastPlaylistWorker.perform_async(current_user.active_room_id)

      {
        room_playlist_records: records,
        errors: @errors
      }
    end

    private

    def update_records!(room, ordered_records, existing_record_ids)
      room.with_lock do
        ensure_user_in_rotation!(room)
        # Note:  We may actually be removing the last song from the room
        #        in this call, but we'll allow the queue management
        #        worker to clean that up.
        room.update!(waiting_songs: true) unless room.waiting_songs
        destroy_absent_records!(existing_record_ids)

        existing_records = existing_records_by_id(existing_record_ids).to_a
        ordered_records.map.with_index do |ordered_record, idx|
          ensure_record!(
            record_id: ordered_record[:room_playlist_record_id],
            song_id: ordered_record[:song_id],
            order: idx,
            existing_records: existing_records
          )
        end.compact
      end
    end

    def ensure_user_in_rotation!(room)
      return if room.user_rotation.include?(current_user.id)

      rotation = room.user_rotation << current_user.id
      room.update!(user_rotation: rotation)
    end

    def destroy_absent_records!(existing_record_ids)
      t = RoomPlaylistRecord.arel_table
      RoomPlaylistRecord
        .where(user: current_user, room_id: current_user.active_room_id)
        .waiting
        .where(t[:id].not_in(existing_record_ids))
        .destroy_all
    end

    def existing_records_by_id(existing_record_ids)
      RoomPlaylistRecord.includes(:room, :song, :user).where(
        id: existing_record_ids,
        user: current_user,
        play_state: :waiting
      )
    end

    def ensure_record!(record_id:, song_id:, order:, existing_records:)
      if record_id.present?
        existing_record = existing_records.find { |r| r[:id] == record_id }
        return if existing_record.blank?

        existing_record.update!(order: order)
        existing_record
      else
        return unless Song.exists?(song_id)

        RoomPlaylistRecord.create!(
          room_id: current_user.active_room_id,
          song_id: song_id,
          user: current_user,
          play_state: :waiting,
          order: order
        )
      end
    end
  end
end
