# frozen_string_literal: true

module Mutations
  class PasswordResetInitiate < Mutations::BaseMutation
    argument :email, Types::EmailType, required: true

    field :errors, [ String ], null: false

    def ready?(**_args)
      true
    end

    def resolve(email:)
      user = User.find_by(email: email)
      return { errors: [] } if user.blank?

      token = user.start_password_reset!
      send_password_reset_email!(user.id, token)

      { errors: [] }
    end

    private

    def send_password_reset_email!(user_id, token)
      EmailPasswordResetWorker.perform_async(user_id, token)
    end
  end
end
