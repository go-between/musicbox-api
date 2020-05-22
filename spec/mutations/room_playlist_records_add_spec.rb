# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Playlist Record Add", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation RoomPlaylistRecordsAdd($ids: [ID!]!) {
        roomPlaylistRecordsAdd(input:{
          ids: $ids
        }) {
          errors
        }
      }
    )
  end

  let(:room) { create(:room) }
  let(:current_user) { create(:user, active_room: room) }
  let(:song1) { create(:song) }
  let(:song2) { create(:song) }

  describe "success" do
    it "adds records to the room playlist when none exist" do
      graphql_request(query: query, user: current_user, variables: { ids: [song1.id, song2.id] })

      record1 = RoomPlaylistRecord.find_by(user: current_user, room: room, song: song1)
      expect(record1.order).to eq(0)

      record2 = RoomPlaylistRecord.find_by(user: current_user, room: room, song: song2)
      expect(record2.order).to eq(1)
    end

    it "adds a record to the end of an existing user's playlist" do
      create(:room_playlist_record, order: 0, room: room, user: current_user)
      create(:room_playlist_record, order: 1, room: room, user: current_user)
      create(:room_playlist_record, order: 2, room: room, user: current_user)

      graphql_request(query: query, user: current_user, variables: { ids: [song1.id, song2.id] })

      record1 = RoomPlaylistRecord.find_by(user: current_user, room: room, song: song1)
      expect(record1.order).to eq(3)

      record1 = RoomPlaylistRecord.find_by(user: current_user, room: room, song: song2)
      expect(record1.order).to eq(4)
    end
  end
end
