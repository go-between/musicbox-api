# frozen_string_literal: true

module Mutations
  class UserLibraryRecordDelete < Mutations::BaseMutation
    argument :id, ID, required: true

    field :errors, [String], null: true

    def resolve(id:)
      record = UserLibraryRecord.find_by(song_id: id, user: context[:current_user])
      return { errors: ["Can't find song to delete"] } if record.blank?

      record.destroy!
      {
        errors: []
      }
    end
  end
end
