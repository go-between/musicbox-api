# frozen_string_literal: true

module Mutations
  class TagRemove < Mutations::BaseMutation
    argument :tag_id, ID, required: true
    argument :song_ids, [ID], required: true

    field :errors, [String], null: true

    def resolve(tag_id:, song_ids:)
      tag = current_user.tags.find_by(id: tag_id)

      return { errors: ["Tag must be present"] } if tag.blank?

      TagSong.where(tag_id: tag_id, song_id: song_ids).delete_all

      {
        errors: []
      }
    end
  end
end
