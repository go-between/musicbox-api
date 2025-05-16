# frozen_string_literal: true

module Mutations
  class RoomActivate < Mutations::BaseMutation
    argument :room_id, ID, required: true

    field :room, Types::RoomType, null: true
    field :errors, [ String ], null: true

    def resolve(room_id:)
      room = Room.find_by(id: room_id, team: context[:current_user].teams)
      if room.blank?
        return {
          room: nil,
          errors: [ "Room #{room_id} does not exist" ]
        }
      end

      current_user.update!(active_room_id: room_id, active_team_id: room.team_id)

      BroadcastTeamWorker.perform_async(current_user.active_team_id)

      {
        room: room,
        errors: []
      }
    end
  end
end
