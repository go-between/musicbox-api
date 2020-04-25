# frozen_string_literal: true

module Mutations
  class RecommendationCreate < Mutations::BaseMutation
    argument :youtube_id, ID, required: true
    argument :recommend_to_user, ID, required: true

    field :errors, [String], null: true

    def resolve(youtube_id:, recommend_to_user:)
      song = Song.find_by(youtube_id: youtube_id)
      return { errors: ["Song must exist"] } if song.blank?

      to_user = User.find(recommend_to_user)
      return { errors: ["User must exist"] } if to_user.blank?
      return { errors: ["User already has song"] } if to_user.songs.include?(song)

      UserLibraryRecord.create!(
        user: to_user,
        song: song,
        from_user_id: current_user.id,
        source: "pending_recommendation"
      )

      {
        errors: []
      }
    end
  end
end
