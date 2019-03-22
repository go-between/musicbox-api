# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include JsonHelper

  describe "#create" do
    it "can be created with a room, song, and user" do
      room = create(:room)
      song = create(:song)
      user = create(:user)
      jsonapi_post("/api/v1/room_queues", {
        data: {
          type: "room_queues",
          attributes: {
            order: 1
          },
          relationships: {
            room: { data: { id: room.id, type: "rooms" } },
            song: { data: { id: song.id, type: "songs" } },
            user: { data: { id: user.id, type: "users" } },
          },
        }
      })

      rq = RoomQueue.find(json_body.dig(:data, :id))
      expect(rq.room).to eq(room)
      expect(rq.song).to eq(song)
      expect(rq.user).to eq(user)
    end
  end
end
