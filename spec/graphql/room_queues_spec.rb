# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include JsonHelper

  def query(order:, room_id:, song_id:, user_id:)
    %(
      mutation {
        createRoomQueue(input:{
          order: "#{order}",
          roomId: "#{room_id}"
          songId: "#{song_id}"
          userId: "#{user_id}"
        }) {
          roomQueue {
            id
            order
            room {
              id
            }
            song {
              id
            }
            user {
              id
            }
          }
          errors
        }
      }
    )
  end

  describe "#create" do
    let(:room) { create(:room) }
    let(:song) { create(:song) }
    let(:user) { create(:user) }
    it "can be created with a room, song, and user" do
      q = query(order: 1, room_id: room.id, song_id: song.id, user_id: user.id)
      post('/api/v1/graphql', params: { query: q })
      data = json_body.dig(:data, :createRoomQueue)

      id = data.dig(:roomQueue, :id)
      rq = RoomQueue.find(id)
      expect(rq.room).to eq(room)
      expect(rq.song).to eq(song)
      expect(rq.user).to eq(user)
    end

    it "broadcasts enqueued songs" do
      expect do
        q = query(order: 1, room_id: room.id, song_id: song.id, user_id: user.id)
        post('/api/v1/graphql', params: { query: q })
      end.to have_broadcasted_to("queue").and(have_broadcasted_to("now_playing"))
    end

    context "when missing required attributes" do
      it "fails to persist when room is not specified" do
        q = query(order: 1, room_id: SecureRandom.uuid, song_id: song.id, user_id: user.id)
        post('/api/v1/graphql', params: { query: q })
        data = json_body.dig(:data, :createRoomQueue)

        expect(data[:roomQueue]).to be_nil
        expect(data[:errors]).to match_array([include("Room must exist")])
      end

      it "fails to persist when song is not specified" do
        q = query(order: 1, room_id: room.id, song_id: SecureRandom.uuid, user_id: user.id)
        post('/api/v1/graphql', params: { query: q })
        data = json_body.dig(:data, :createRoomQueue)

        expect(data[:roomQueue]).to be_nil
        expect(data[:errors]).to match_array([include("Song must exist")])
      end

      it "fails to persist when user is not specified" do
        q = query(order: 1, room_id: room.id, song_id: song.id, user_id: SecureRandom.uuid)
        post('/api/v1/graphql', params: { query: q })
        data = json_body.dig(:data, :createRoomQueue)

        expect(data[:roomQueue]).to be_nil
        expect(data[:errors]).to match_array([include("User must exist")])
      end
    end
  end
end
