# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include JsonHelper

  describe "#create" do
    it "can be created" do
      room = create(:room)
      expect(room.songs.size).to eq(0)

      jsonapi_post("/api/v1/rooms/#{room.id}/songs", {
        data: {
          type: "songs",
          attributes: {
            name: "foo",
            url: "http://bar",
            duration_in_seconds: 5
          },
        }
      })

      id = json_body.dig(:data, :id)
      expect(Song.exists?(id)).to eq(true)
    end
  end
end
