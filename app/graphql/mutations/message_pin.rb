# frozen_string_literal: true

module Mutations
  class MessagePin < Mutations::BaseMutation
    argument :message_id, ID, required: true
    argument :pin, Boolean, required: true

    field :message, Types::MessageType, null: true
    field :errors, [ String ], null: true

    def resolve(message_id:, pin:)
      message = Message.find_by(user: current_user, id: message_id)

      unless message.present?
        return {
          message: nil,
          errors: [ "Message must belong to the current user" ]
        }
      end

      message.update!(pinned: pin)
      BroadcastPinnedMessagesWorker.perform_async(message.room_id, message.song_id)

      {
        message: message,
        errors: []
      }
    end
  end
end
