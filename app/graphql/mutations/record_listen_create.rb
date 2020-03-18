# frozen_string_literal: true

module Mutations
  class RecordListenCreate < Mutations::BaseMutation
    argument :record_id, ID, required: true
    argument :approval, Int, required: true

    field :record_listen, Types::RecordListenType, null: true
    field :errors, [String], null: true

    def resolve(record_id:, approval:)
      unless record_playing?(record_id)
        return {
          record_listen: nil,
          errors: ["Record must be playing in the active room"]
        }
      end

      approval = ensure_approval_range(approval)
      listen = ensure_record_listen!(record_id)
      listen.update!(approval: approval) if listen.approval != approval

      { record_listen: listen, errors: [] }
    end

    private

    def ensure_approval_range(approval)
      return 0 if approval.negative?

      [approval, 3].min
    end

    def ensure_record_listen!(record_id)
      record = RoomPlaylistRecord.find(record_id)
      RecordListen.find_or_create_by!(room_playlist_record_id: record_id, song_id: record.song_id, user_id: current_user.id)
    end

    def record_playing?(record_id)
      record_id == current_user&.active_room&.current_record_id
    end
  end
end
