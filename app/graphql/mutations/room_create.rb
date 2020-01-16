# frozen_string_literal: true

module Mutations
  class RoomCreate < Mutations::BaseMutation
    argument :name, ID, required: true

    field :room, Types::RoomType, null: true
    field :errors, [String], null: true

    def resolve(name:)
      room = Room.new(name: name)

      unless room.valid?
        return {
          room: nil,
          errors: room.errors.full_messages
        }
      end

      room.save!
      set_room_team_to_current_user_active_team!(room)

      {
        room: room,
        errors: []
      }
    end

    private

    def set_room_team_to_current_user_active_team!(room)
      room.update!(team: context[:current_user].active_team)
    end
  end
end
