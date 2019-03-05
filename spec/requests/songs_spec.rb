# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  # JSON.parse(response.body, symbolize_names: true)

  describe "#create" do
    it "can be posted to a room" do
      room = Room.create!
      expect(room.songs.size).to eq(0)

      post("/api/v1/rooms/#{room.id}/songs", params: {
        data: {
          type: "songs",
          attributes: {
            name: "foo",
            url: "http://bar",
            duration_in_seconds: 5
          }
        },
        relationships: {
          room: {
            data: { type: "rooms", id: "#{room.id}" }
          }
        }
      })

      expect(room.songs.size).to eq(1)
    end
  end
end
