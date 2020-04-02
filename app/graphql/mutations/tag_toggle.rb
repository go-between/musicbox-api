# frozen_string_literal: true

module Mutations
  class TagToggle < Mutations::BaseMutation
    argument :tag_id, ID, required: true
    argument :add_song_ids, [ID], required: true
    argument :remove_song_ids, [ID], required: true

    field :tag, Types::TagType, null: true
    field :errors, [String], null: true

    def resolve(tag_id:, add_song_ids:, remove_song_ids:)
      tag = current_user.tags.find_by(id: tag_id)

      return { errors: ["Tag must be present"] } if tag.blank?

      add_tag_to_songs!(tag_id, add_song_ids)
      remove_tag_from_songs!(tag_id, remove_song_ids)

      {
        tag: tag,
        errors: []
      }
    end

    private

    def add_tag_to_songs!(tag_id, song_ids)
      return if song_ids.blank?

      tags_songs = song_ids.map do |song_id|
        {
          tag_id: tag_id,
          song_id: song_id,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end
      TagSong.insert_all(tags_songs)
    end

    def remove_tag_from_songs!(tag_id, song_ids)
      return if song_ids.blank?

      TagSong.where(tag_id: tag_id, song_id: song_ids).delete_all
    end
  end
end
