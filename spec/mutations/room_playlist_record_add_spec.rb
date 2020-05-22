# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Playlist Record Add", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation RoomPlaylistRecordAdd($id: ID!) {
        roomPlaylistRecordAdd(input:{
          id: $id
        }) {
          errors
        }
      }
    )
  end

  let(:room) { create(:room) }
  let(:current_user) { create(:user, active_room: room) }

  describe "success" do
    it "adds a record to the room playlist when none exist" do
      song = create(:song)

      graphql_request(query: query, user: current_user, variables: { id: song.id })
      record = RoomPlaylistRecord.find_by(user: current_user, room: room, song: song)
      expect(record.order).to eq(0)
    end

    it "adds a record to the end of an existing user's playlist" do
      create(:room_playlist_record, order: 0, room: room, user: current_user)
      create(:room_playlist_record, order: 1, room: room, user: current_user)
      create(:room_playlist_record, order: 2, room: room, user: current_user)
      song = create(:song)

      graphql_request(query: query, user: current_user, variables: { id: song.id })
      record = RoomPlaylistRecord.find_by(user: current_user, room: room, song: song)
      expect(record.order).to eq(3)
    end
  end
end
