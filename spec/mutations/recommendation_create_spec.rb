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

      # Pending recommendations are not returned in a user's songs
      expect(other_user.songs).not_to include(song)
      record = LibraryRecord.find_by(song_id: song.id, user: other_user)
      expect(record.from_user_id).to eq(current_user.id)
      expect(record.source).to eq("pending_recommendation")
    end
  end

  describe "failure" do
    it "does not create a recommendation if the user already has the song in their library" do
      song = create(:song, youtube_id: "the-youtube-id")
      other_user = create(:user)
      LibraryRecord.create!(user: other_user, song: song, source: "")

      expect do
        graphql_request(
          query: query,
          variables: { youtubeId: "the-youtube-id", recommendToUser: other_user.id },
          user: current_user
        )
      end.to not_change(LibraryRecord, :count)
    end

    it "does not create a recommendation if the user has already been recommended the song" do
      song = create(:song, youtube_id: "the-youtube-id")
      other_user = create(:user)
      LibraryRecord.create!(user: other_user, song: song, source: "pending_recommendation")

      expect do
        graphql_request(
          query: query,
          variables: { youtubeId: "the-youtube-id", recommendToUser: other_user.id },
          user: current_user
        )
      end.to not_change(LibraryRecord, :count)
    end
  end
end
