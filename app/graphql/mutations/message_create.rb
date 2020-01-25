# frozen_string_literal: true

module Mutations
  class MessageCreate < Mutations::BaseMutation
    argument :message, String, required: true

    field :message, Types::MessageType, null: true
    field :errors, [String], null: true

    def resolve(message:)
      unless current_user.active_room_id.present?
        return {
          message: nil,
          errors: ["Must be in an active room"]
        }
      end

      new_message = create_message!(message)
      BroadcastMessageWorker.perform_async(current_user.active_room_id, new_message.id)

      {
        message: new_message,
        errors: []
      }
    end

    private

    def create_message!(message)
      Message.create!(
        message: message,
        room_playlist_record: current_user.active_room.current_record,
        room_id: current_user.active_room_id,
        user_id: current_user.id
      )
    end
  end
end
