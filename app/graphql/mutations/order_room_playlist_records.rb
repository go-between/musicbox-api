# frozen_string_literal: true

module Mutations
  class OrderRoomPlaylistRecords < Mutations::BaseMutation
    argument :room_id, ID, required: true
    argument :ordered_records, [Types::OrderedRoomPlaylistRecord], required: true

    field :errors, [String], null: true

    def resolve(room_id:, ordered_records:)
      room = Room.find(room_id)
      ensure_user_in_rotation!(room)

      @errors = []

      records = initialize_records!(room_id, ordered_records)
      records.each_with_index { |r, i| r.update!(order: i) }

      BroadcastPlaylistWorker.perform_async(room_id)
      {
        errors: @errors
      }
    end

    private

    def ensure_user_in_rotation!(room)
      room.with_lock do
        return if room.user_rotation.include?(context[:current_user].id)

        rotation = room.user_rotation << context[:current_user].id

        room.update!(user_rotation: rotation)
      end
    end

    def initialize_records!(room_id, ordered_records)
      ordered_records.map do |ordered_record, _index|
        record = initialize_record!(
          ordered_record[:room_playlist_record_id],
          ordered_record[:song_id],
          room_id
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

    def initialize_record!(room_playlist_record_id, song_id, room_id)
      if room_playlist_record_id.present?
        RoomPlaylistRecord.find_by(
          id: room_playlist_record_id,
          user: context[:current_user],
          play_state: :waiting
        )
      else
        return unless Song.exists?(id: song_id)

        RoomPlaylistRecord.create!(
          room_id: room_id,
          song_id: song_id,
          user: context[:current_user],
          play_state: :waiting
        )
      end
    end
  end
end
