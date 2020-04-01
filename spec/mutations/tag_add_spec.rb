# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tag Add", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation TagAdd($tagId: ID!, $songIds: [ID!]!) {
        tagAdd(input:{
          tagId: $tagId,
          songIds: $songIds
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }
  let(:tag) { create(:tag, user: current_user) }
  let(:song1) { create(:song, users: [current_user]) }
  let(:song2) { create(:song, users: [current_user]) }
  let(:song3) { create(:song, users: [current_user]) }

  describe "adding an association" do
    it "associates new songs to the tag, noops on songs that already have the tag" do
      TagSong.create(tag_id: tag.id, song_id: song1.id)

      expect do
        graphql_request(
          query: query,
          variables: { tagId: tag.id, songIds: [song1.id, song2.id, song3.id] },
          user: current_user
        )
      end.to change(TagSong, :count).by(2)

      expect(song1.tags).to include(tag)
      expect(song2.tags).to include(tag)
      expect(song3.tags).to include(tag)
    end
  end

  context "when tag is misconfigured" do
    it "returns an error when tag does not exist" do
      expect do
        graphql_request(
          query: query,
          variables: { tagId: SecureRandom.uuid, songIds: [song1.id] },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagAdd, :tag)).to be_nil
      expect(json_body.dig(:data, :tagAdd, :errors)).to include("Tag must be present")
    end

    it "returns an error when tag is not associated with the user" do
      other_tag = create(:tag, user: create(:user))
      expect do
        graphql_request(
          query: query,
          variables: { tagId: other_tag.id, songIds: [song1.id] },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagAdd, :tag)).to be_nil
      expect(json_body.dig(:data, :tagAdd, :errors)).to include("Tag must be present")
    end
  end
end
