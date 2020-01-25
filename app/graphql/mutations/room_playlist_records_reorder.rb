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
      @errors = []
      ensure_user_in_rotation!

      records = initialize_records!(ordered_records)
      destroy_absent_records!(records)

      records.each_with_index { |r, i| r.update!(order: i) }
      BroadcastPlaylistWorker.perform_async(current_user.active_room_id)

      {
        room_playlist_records: records,
        errors: @errors
      }
    end

    private

    def ensure_user_in_rotation!
      room = Room.find(current_user.active_room_id)
      room.with_lock do
        return if room.user_rotation.include?(current_user.id)

        rotation = room.user_rotation << current_user.id

        room.update!(user_rotation: rotation)
      end
    end

    def destroy_absent_records!(records)
      t = RoomPlaylistRecord.arel_table
      RoomPlaylistRecord
        .where(user: current_user, room_id: current_user.active_room_id)
        .waiting
        .where(t[:id].not_in(records.map(&:id)))
        .destroy_all
    end

    def initialize_records!(ordered_records)
      ordered_records.map do |ordered_record, _index|
        record = initialize_record!(
          ordered_record[:room_playlist_record_id],
          ordered_record[:song_id]
        )

        unless record
          msg = %W[
            Cannot order record id: #{ordered_record[:room_playlist_record_id]}, song id: #{ordered_record[:song_id]}
          ]
          @errors << msg
          next
        end

        record
      end.compact
    end

    def initialize_record!(room_playlist_record_id, song_id)
      if room_playlist_record_id.present?
        RoomPlaylistRecord.find_by(
          id: room_playlist_record_id,
          user: current_user,
          play_state: :waiting
        )
      else
        return unless Song.exists?(id: song_id)

        RoomPlaylistRecord.create!(
          room_id: current_user.active_room_id,
          song_id: song_id,
          user: current_user,
          play_state: :waiting
        )
      end
    end
  end
end
