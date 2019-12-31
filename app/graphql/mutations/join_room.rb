# frozen_string_literal: true

module Mutations
  class JoinRoom < Mutations::BaseMutation
    argument :room_id, ID, required: true

    field :room, Types::RoomType, null: true
    field :errors, [String], null: true

    def resolve(room_id:)
      room = Room.find_by(id: room_id)
      if room.blank?
        return {
          room: nil,
          errors: ["Room #{room_id} does not exist"]
        }
      end

      context[:current_user].update!(active_room_id: room_id)
      BroadcastUsersWorker.perform_async(room.id)

      {
        room: room,
        errors: []
      }
    end
  end
end
