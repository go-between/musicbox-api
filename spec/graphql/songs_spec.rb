# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include JsonHelper

  def query(name:, youtube_id:)
    %(
      mutation {
        createSong(input:{
          name: "#{name}",
          youtubeId: "#{youtube_id}"
        }) {
          song {
            id
            name
            youtubeId
          }
          errors
        }
      }
    )
  end

  describe "#create" do
    it "can be created" do
      post('/api/v1/graphql', params: { query: query(name: "the name", youtube_id: "an-id") })
      data = json_body.dig(:data, :createSong)
      id = data.dig(:song, :id)

      expect(Song.exists?(id)).to eq(true)
      expect(data[:errors]).to be_blank
    end

    it "allows find-or-create by youtube_id" do
      song = create(:song, youtube_id: "the-youtube-id")

      expect do
        post('/api/v1/graphql', params: { query: query(name: "the name", youtube_id: "the-youtube-id") })
        data = json_body.dig(:data, :createSong)
        id = data.dig(:song, :id)

        expect(song.id).to eq(id)
        expect(data[:errors]).to be_blank
      end.to_not change(Song, :count)
    end
  end

  context "when missing required attributes" do
    it "fails to persist when youtube_id is not specified" do
      expect do
        post('/api/v1/graphql', params: { query: query(name: "the name", youtube_id: nil) })
        data = json_body.dig(:data, :createSong)

        expect(data[:song]).to be_nil
        expect(data[:errors]).to match_array([include("Youtube can't be blank")])
      end.to_not change(Song, :count)
    end
  end
end
