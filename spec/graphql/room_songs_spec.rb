# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include AuthHelper
  include JsonHelper

  def query(order:, room_id:, song_id:)
    %(
      mutation {
        createRoomSong(input:{
          order: #{order},
          roomId: "#{room_id}"
          songId: "#{song_id}"
        }) {
          roomSong {
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
    it "can be created with a room, song, and user" do
      q = query(order: 1, room_id: room.id, song_id: song.id)
      authed_post('/api/v1/graphql', query: q)
      data = json_body.dig(:data, :createRoomSong)

      id = data.dig(:roomSong, :id)
      rq = RoomSong.find(id)
      expect(rq.room).to eq(room)
      expect(rq.song).to eq(song)
      expect(rq.user).to eq(current_user)
    end

    xit "broadcasts enqueued songs" do
      expect do
        q = query(order: 1, room_id: room.id, song_id: song.id)
        authed_post('/api/v1/graphql', query: q)

      end.to have_broadcasted_to("queue").and(have_broadcasted_to("now_playing"))
    end

    context "when missing required attributes" do
      it "fails to persist when room is not specified" do
        q = query(order: 1, room_id: SecureRandom.uuid, song_id: song.id)
        authed_post('/api/v1/graphql', query: q)

        data = json_body.dig(:data, :createRoomSong)

        expect(data[:RoomSong]).to be_nil
        expect(data[:errors]).to match_array([include("Room must exist")])
      end

      it "fails to persist when song is not specified" do
        q = query(order: 1, room_id: room.id, song_id: SecureRandom.uuid)
        authed_post('/api/v1/graphql', query: q)

        data = json_body.dig(:data, :createRoomSong)

        expect(data[:RoomSong]).to be_nil
        expect(data[:errors]).to match_array([include("Song must exist")])
      end
    end
  end
end
