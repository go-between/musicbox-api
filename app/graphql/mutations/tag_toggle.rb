# frozen_string_literal: true

module Mutations
  class TagToggle < Mutations::BaseMutation
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

      toggle!(tag: tag, song: song)

      {
        tag: tag,
        errors: []
      }
    end

    private

    def toggle!(tag:, song:)
      tag_song = TagSong.find_by(tag_id: tag.id, song_id: song.id)
      if tag_song.present?
        tag_song.destroy!
      else
        tag.songs << song unless tag.songs.exists?(song.id)
      end
    end
  end
end
