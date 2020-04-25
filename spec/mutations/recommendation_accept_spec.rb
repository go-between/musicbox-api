# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommendation Accept", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation RecommendationAccept($libraryRecordId: ID!) {
        recommendationAccept(input:{
          libraryRecordId: $libraryRecordId
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }

  describe "success" do
    it "allows user to acccept a recommendation" do
      song = create(:song, youtube_id: "the-youtube-id")
      other_user = create(:user)
      record = UserLibraryRecord.create!(
        song: song,
        user: current_user,
        from_user_id: other_user.id,
        source: "pending_recommendation"
      )

      graphql_request(
        query: query,
        variables: { libraryRecordId: record.id },
        user: current_user
      )

      record.reload
      expect(record.from_user).to eq(other_user)
      expect(record).to be_accepted_recommendation
    end
  end
end
