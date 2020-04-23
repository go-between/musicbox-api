# frozen_string_literal: true

module Mutations
  class PasswordResetComplete < Mutations::BaseMutation
    argument :email, Types::EmailType, required: true
    argument :password, String, required: true
    argument :token, String, required: true

    field :access_token, ID, null: true
    field :errors, [String], null: false

    def ready?(**_args)
      true
    end

    def resolve(email:, password:, token:)
      user = ensure_user(email, token)
      return { errors: ["Invalid token"] } if user.blank?
      return { errors: ["Expired token"] } unless user.reset_password_period_valid?
      return { errors: ["Invalid new password"] } unless user.reset_password(password, password)

      {
        access_token: access_token_for(user.id),
        errors: []
      }
    end

    private

    def ensure_user(email, token)
      maybe_user = User.with_reset_password_token(token)
      return unless maybe_user.present? && maybe_user.email == email

      maybe_user
    end
  end
end
