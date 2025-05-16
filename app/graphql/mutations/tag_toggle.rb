# frozen_string_literal: true

module Mutations
  class TagToggle < Mutations::BaseMutation
    argument :tag_id, ID, required: true
    argument :add_ids, [ ID ], required: true
    argument :remove_ids, [ ID ], required: true

    field :tag, Types::TagType, null: true
    field :errors, [ String ], null: true

    def resolve(tag_id:, add_ids:, remove_ids:)
      tag = current_user.tags.find_by(id: tag_id)

      return { errors: [ "Tag must be present" ] } if tag.blank?

      add_to_records!(tag_id, add_ids)
      remove_tag_from_songs!(tag_id, remove_ids)

      {
        tag: tag,
        errors: []
      }
    end

    private

    def add_to_records!(tag_id, library_record_ids)
      return if library_record_ids.blank?

      tags_library_records = library_record_ids.map do |library_record_id|
        {
          tag_id: tag_id,
          library_record_id: library_record_id,
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end
      TagLibraryRecord.insert_all(tags_library_records)
    end

    def remove_tag_from_songs!(tag_id, library_record_ids)
      return if library_record_ids.blank?

      TagLibraryRecord.where(tag_id: tag_id, library_record_id: library_record_ids).delete_all
    end
  end
end
