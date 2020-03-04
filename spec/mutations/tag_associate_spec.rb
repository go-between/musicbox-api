# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tag Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation TagAssociate($tagId: ID!, $songId: ID!) {
        tagAssociate(input:{
          tagId: $tagId,
          songId: $songId
        }) {
          tag {
            id
            name
            user {
              id
            }
            songs {
              id
            }
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }
  let(:tag) { create(:tag, user: current_user) }
  let(:song) { create(:song, users: [current_user]) }

  describe "adding an association" do
    it "associates the song to the tag" do
      expect do
        graphql_request(
          query: query,
          variables: { tagId: tag.id, songId: song.id },
          user: current_user
        )
      end.to change(TagSong, :count).by(1)

      data = json_body.dig(:data, :tagAssociate, :tag, :songs)
      song_ids = data.map { |song| song[:id] }

      expect(song_ids).to match_array(song_ids)
    end

    it "noops when a song is already associated to a tag" do
      TagSong.create!(tag: tag, song: song)

      expect do
        graphql_request(
          query: query,
          variables: { tagId: tag.id, songId: song.id },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      data = json_body.dig(:data, :tagAssociate, :tag, :songs)
      song_ids = data.map { |song| song[:id] }

      expect(song_ids).to match_array(song_ids)
    end
  end

  context "when tag is misconfigured" do
    it "returns an error when tag does not exist" do
      expect do
        graphql_request(
          query: query,
          variables: { tagId: SecureRandom.uuid, songId: song.id },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagAssociate, :tag)).to be_nil
      expect(json_body.dig(:data, :tagAssociate, :errors)).to include("Tag and Song must be present")
    end

    it "returns an error when tag is not associated with the user" do
      other_tag = create(:tag, user: create(:user))
      expect do
        graphql_request(
          query: query,
          variables: { tagId: other_tag.id, songId: song.id },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagAssociate, :tag)).to be_nil
      expect(json_body.dig(:data, :tagAssociate, :errors)).to include("Tag and Song must be present")
    end
  end

  context "when song is misconfigured" do
    it "returns an error when song does not exist" do
      expect do
        graphql_request(
          query: query,
          variables: { tagId: tag.id, songId: SecureRandom.uuid },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagAssociate, :tag)).to be_nil
      expect(json_body.dig(:data, :tagAssociate, :errors)).to include("Tag and Song must be present")
    end

    it "returns an error when song is not associated with the user" do
      other_song = create(:song, users: [create(:user)])
      expect do
        graphql_request(
          query: query,
          variables: { tagId: tag.id, songId: other_song.id },
          user: current_user
        )
      end.not_to change(TagSong, :count)

      expect(json_body.dig(:data, :tagAssociate, :tag)).to be_nil
      expect(json_body.dig(:data, :tagAssociate, :errors)).to include("Tag and Song must be present")
    end
  end
end
