# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tag Add", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation TagToggle($tagId: ID!, $addSongIds: [ID!]!, $removeSongIds: [ID!]!) {
        tagToggle(input:{
          tagId: $tagId,
          addSongIds: $addSongIds,
          removeSongIds: $removeSongIds
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
  let(:song4) { create(:song, users: [current_user]) }

  describe "adding an association" do
    it "adds tag and removes tag from songs" do
      TagSong.create(tag_id: tag.id, song_id: song1.id)
      TagSong.create(tag_id: tag.id, song_id: song2.id)

      graphql_request(
        query: query,
        variables: { tagId: tag.id, addSongIds: [song1.id, song3.id], removeSongIds: [song2.id, song4.id] },
        user: current_user
      )

      expect(song1.tags).to include(tag)
      expect(song2.tags).not_to include(tag)
      expect(song3.tags).to include(tag)
      expect(song4.tags).not_to include(tag)
    end
  end

  context "when tag is misconfigured" do
    it "returns an error when tag does not exist" do
      expect do
        graphql_request(
          query: query,
          variables: { tagId: SecureRandom.uuid, addSongIds: [song1.id], removeSongIds: [song2.id] },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagToggle, :tag)).to be_nil
      expect(json_body.dig(:data, :tagToggle, :errors)).to include("Tag must be present")
    end

    it "returns an error when tag is not associated with the user" do
      other_tag = create(:tag, user: create(:user))
      expect do
        graphql_request(
          query: query,
          variables: { tagId: other_tag.id, addSongIds: [song1.id], removeSongIds: [song2.id] },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagToggle, :tag)).to be_nil
      expect(json_body.dig(:data, :tagToggle, :errors)).to include("Tag must be present")
    end
  end
end
