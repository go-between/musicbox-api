# frozen_string_literal: true

module Mutations
  class TagAssociate < Mutations::BaseMutation
    argument :tag_id, ID, required: true
    argument :song_id, ID, required: true

    field :tag, Types::TagType, null: true
    field :errors, [String], null: true

    def resolve(tag_id:, song_id:)
      tag = current_user.tags.find_by(id: tag_id)
      song = current_user.songs.find_by(id: song_id)

      unless tag.present? && song.present?
        return {
          tag: nil,
          errors: ["Tag and Song must be present"]
        }
      end

      tag.songs << song unless tag.songs.exists?(song.id)

      {
        tag: tag,
        errors: []
      }
    end
  end
end
