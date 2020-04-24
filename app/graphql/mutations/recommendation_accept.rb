# frozen_string_literal: true

module Mutations
  class RecommendationAccept < Mutations::BaseMutation
    argument :library_record_id, ID, required: true

    field :errors, [String], null: true

    def resolve(library_record_id:)
      record = UserLibraryRecord.find_by(id: library_record_id, user: current_user, source: "pending_recommendation")
      return { errors: ["No recommendation"] } if record.blank?

      record.update!(source: "accepted_recommendation")

      {
        errors: []
      }
    end
  end
end
