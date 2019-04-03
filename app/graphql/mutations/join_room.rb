module Mutations
  class JoinRoom < Mutations::BaseMutation
    argument :room_id, ID, required: true

    field :room, Types::RoomType, null: true
    field :errors, [String], null: true

    def resolve(room_id:)
      room = Room.find_by(id: room_id)
      return {
        room: nil,
        errors: ["Room #{room_id} does not exist"]
      } if room.blank?

      context[:current_user].update!(room_id: room_id)

      {
        room: room,
        errors: [],
      }
    end
  end
end
