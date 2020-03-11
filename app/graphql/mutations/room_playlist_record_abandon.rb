# frozen_string_literal: true

module Mutations
  class RoomPlaylistRecordAbandon < Mutations::BaseMutation
    field :errors, [String], null: true

    def resolve
      error = guard_abandon
      return { errors: [error] } if error.present?

      current_user.active_room.update!(playing_until: 1.second.ago)

      {
        errors: []
      }
    end

    private

    def guard_abandon
      return "Not in active room" if current_user.active_room.blank?
      return "No current record" if current_user.active_room.current_record.blank?
      return "User does not own current song" if current_user.id != current_record_user
    end

    def current_record_user
      current_user.active_room.current_record.user_id
    end
  end
end
