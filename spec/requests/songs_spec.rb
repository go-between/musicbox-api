# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  describe "#create" do
    it "can be posted to a room" do
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
          relationships: {
            room: {
              data: { type: "rooms", id: "#{room.id}" }
            }
          }
        }
      })

      expect(room.reload.songs.size).to eq(1)
    end
  end
end
