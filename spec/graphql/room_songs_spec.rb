# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs", type: :request do
  include AuthHelper
  include JsonHelper

  describe "#create" do
    def create_query(order:, room_id:, song_id:)
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

    let(:room) { create(:room) }
    let(:song) { create(:song) }
    it "can be created with a room, song, and user" do
      q = create_query(order: 1, room_id: room.id, song_id: song.id)
      authed_post('/api/v1/graphql', query: q)
      data = json_body.dig(:data, :createRoomSong)

      id = data.dig(:roomSong, :id)
      rq = RoomSong.find(id)
      expect(rq.room).to eq(room)
      expect(rq.song).to eq(song)
      expect(rq.user).to eq(current_user)
    end

    it "broadcasts enqueued songs" do
      q = create_query(order: 1, room_id: room.id, song_id: song.id)
      authed_post('/api/v1/graphql', query: q)
      expect(BroadcastQueueWorker).to have_enqueued_sidekiq_job(room.id)
    end

    context "when missing required attributes" do
      it "fails to persist when room is not specified" do
        q = create_query(order: 1, room_id: SecureRandom.uuid, song_id: song.id)
        authed_post('/api/v1/graphql', query: q)

        data = json_body.dig(:data, :createRoomSong)

        expect(data[:RoomSong]).to be_nil
        expect(data[:errors]).to match_array([include("Room must exist")])
      end

      it "fails to persist when song is not specified" do
        q = create_query(order: 1, room_id: room.id, song_id: SecureRandom.uuid)
        authed_post('/api/v1/graphql', query: q)

        data = json_body.dig(:data, :createRoomSong)

        expect(data[:RoomSong]).to be_nil
        expect(data[:errors]).to match_array([include("Song must exist")])
      end
    end
  end

  describe "ordering room songs for a user" do
    let(:room) { create(:room) }
    def order_room_songs_query
      %(
        mutation($roomId: ID!, $orderedSongs: [OrderedSongObject!]!) {
          orderRoomSongs(input:{
            roomId: $roomId
            orderedSongs: $orderedSongs
          }) {
            errors
          }
        }
      )
    end

    it "sets the order on each provided room song to index plus one" do
      rs1 = create(:room_song, order: 1, user: current_user, room: room)
      rs2 = create(:room_song, order: 2, user: current_user, room: room)
      rs3 = create(:room_song, order: 3, user: current_user, room: room)

      ordered_songs = [
        { roomSongId: rs3.id, songId: rs3.song_id },
        { roomSongId: rs1.id, songId: rs1.song_id },
        { roomSongId: rs2.id, songId: rs2.song_id },
      ]
      variables = {
        roomId: room.id,
        orderedSongs: ordered_songs
      }
      authed_post('/api/v1/graphql', query: order_room_songs_query, variables: variables)

      expect(rs1.reload.order).to eq(2)
      expect(rs2.reload.order).to eq(3)
      expect(rs3.reload.order).to eq(1)
    end

    it "adds new songs to the order as provided" do
      rs1 = create(:room_song, order: 1, user: current_user, room: room)
      rs2 = create(:room_song, order: 2, user: current_user, room: room)
      rs3 = create(:room_song, order: 3, user: current_user, room: room)
      queue_id = SecureRandom.uuid
      new_song = create(:song)
      expect(RoomSong.exists?(user: current_user, song_id: new_song.id, room: room)).to eq(false)

      ordered_songs = [
        { roomSongId: rs3.id, songId: rs3.song_id },
        { roomSongId: queue_id, songId: new_song.id},
        { roomSongId: rs1.id, songId: rs1.song_id },
        { roomSongId: rs2.id, songId: rs2.song_id }
      ]
      variables = {
        roomId: room.id,
        orderedSongs: ordered_songs
      }

      authed_post('/api/v1/graphql', query: order_room_songs_query, variables: variables)

      new_room_song = RoomSong.find_by(id: queue_id, user: current_user, song_id: new_song.id, room: room)
      expect(new_room_song.order).to eq(2)
      expect(rs1.reload.order).to eq(3)
      expect(rs2.reload.order).to eq(4)
      expect(rs3.reload.order).to eq(1)
    end

    it "broadcasts the new room song list with expected order" do
      song = create(:song)
      ordered_songs = [
        { roomSongId: SecureRandom.uuid, songId: song.id},
      ]
      variables = {
        roomId: room.id,
        orderedSongs: ordered_songs
      }

      authed_post('/api/v1/graphql', query: order_room_songs_query, variables: variables)
      expect(BroadcastQueueWorker).to have_enqueued_sidekiq_job(room.id)
    end
  end
end
