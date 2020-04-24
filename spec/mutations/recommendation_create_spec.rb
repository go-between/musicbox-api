# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommendation Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation RecommendationCreate($youtubeId: ID!, $recommendToUser: ID!) {
        recommendationCreate(input:{
          youtubeId: $youtubeId,
          recommendToUser: $recommendToUser
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }

  describe "success" do
    it "allows one user to recommend a song to another" do
      song = create(:song, youtube_id: "the-youtube-id")
      other_user = create(:user)

      graphql_request(
        query: query,
        variables: { youtubeId: "the-youtube-id", recommendToUser: other_user.id },
        user: current_user
      )

      expect(other_user.songs).to include(song)
      record = other_user.user_library_records.find_by(song_id: song.id)
      expect(record.from_user_id).to eq(current_user.id)
      expect(record.source).to eq("pending_recommendation")
    end
  end
end
