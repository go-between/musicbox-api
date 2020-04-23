# frozen_string_literal: true

module Mutations
  class UserUpdate < Mutations::BaseMutation
    class UserUpdateInputObject < Types::BaseInputObject
      argument :name, String, required: false
    end

    argument :user, UserUpdateInputObject, required: true
    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(user:)
      attrs = update_with(user)
      return { errors: ["Must specify at least one attribute"] } if attrs.blank?

      current_user.update!(attrs)

      {
        user: current_user,
        errors: []
      }
    end

    def update_with(user)
      {}.tap do |hsh|
        hsh[:name] = user[:name] if user[:name].present?
      end
    end
  end
end
