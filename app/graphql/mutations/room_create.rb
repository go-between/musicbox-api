# frozen_string_literal: true

module Mutations
  class RoomCreate < Mutations::BaseMutation
    argument :name, String, required: true

    field :room, Types::RoomType, null: true
    field :errors, [String], null: true

    def resolve(name:)
      room = Room.new(
        name: name,
        team: current_user.active_team
      )

      unless room.valid?
        return {
          room: nil,
          errors: room.errors.full_messages
        }
      end

      room.save!

      {
        room: room,
        errors: []
      }
    end
  end
end
