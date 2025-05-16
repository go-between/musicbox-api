# frozen_string_literal: true

module Mutations
  class UserPasswordUpdate < Mutations::BaseMutation
    argument :password, String, required: true
    argument :new_password, String, required: true

    field :errors, [ String ], null: true

    def resolve(password:, new_password:)
      return { errors: [ "Invalid password" ] } unless current_user.valid_password?(password)
      return { errors: [ "Insecure password" ] } unless current_user.reset_password(new_password, new_password)

      {
        errors: []
      }
    end
  end
end
