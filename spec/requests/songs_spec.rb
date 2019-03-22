# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include JsonHelper

  describe "#create" do
    it "can be created" do
      jsonapi_post("/api/v1/songs", {
        data: {
          type: "songs",
          attributes: {
            name: "foo",
            url: "http://bar",
            youtube_id: "the-id"
          },
        }
      })

      id = json_body.dig(:data, :id)
      expect(Song.exists?(id)).to eq(true)
    end

    it "allows find-or-create by youtube_id" do
      song = create(:song, youtube_id: "the-youtube-id")

      expect do
        jsonapi_post("/api/v1/songs", {
          data: {
            type: "songs",
            attributes: {
              name: "foo",
              url: "http://bar",
              youtube_id: "the-youtube-id"
            },
          }
        })
      end.to_not change(Song, :count)

      id = json_body.dig(:data, :id)
      expect(song.id).to eq(id)
    end
  end
end
