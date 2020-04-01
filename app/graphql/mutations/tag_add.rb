# frozen_string_literal: true

module Mutations
  class TagAdd < Mutations::BaseMutation
    argument :tag_id, ID, required: true
    argument :song_ids, [ID], required: true

    field :errors, [String], null: true

    def resolve(tag_id:, song_ids:)
      tag = current_user.tags.find_by(id: tag_id)

      return { errors: ["Tag must be present"] } if tag.blank?

      tags_songs = song_ids.map do |song_id|
        {
          tag_id: tag_id,
          song_id: song_id,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end
      TagSong.insert_all(tags_songs)

      {
        errors: []
      }
    end
  end
end
