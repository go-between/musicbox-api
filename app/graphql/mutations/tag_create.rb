# frozen_string_literal: true

module Mutations
  class TagCreate < Mutations::BaseMutation
    argument :name, String, required: true

    field :tag, Types::TagType, null: true
    field :errors, [String], null: true

    def resolve(name:)
      tag = Tag.new(
        name: name,
        user: current_user
      )

      unless tag.valid?
        return {
          tag: nil,
          errors: tag.errors.full_messages
        }
      end

      tag.save!

      {
        tag: tag,
        errors: []
      }
    end
  end
end
