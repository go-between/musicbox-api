# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create Song", type: :request do
  include AuthHelper
  include JsonHelper

  def query(id:)
    %(
      mutation {
        deleteRoomPlaylistRecord(input:{
          id: "#{id}"
        }) {
          errors
        }
      }
    )
  end

  describe "success" do
    it "deletes a room playlist record belonging to the user" do
      record = create(:room_playlist_record, user: current_user)

      authed_post('/api/v1/graphql', query: query(id: record.id))
      data = json_body.dig(:data, :deleteRoomPlaylistRecord)

      expect(data[:errors]).to be_empty
      expect(RoomPlaylistRecord.find_by(id: record.id)).to_not be_present
    end

    it "enqueues a queue management broadcast worker for the room" do
      room = create(:room)
      record = create(:room_playlist_record, room: room, user: current_user)

      expect(BroadcastQueueWorker).to receive(:perform_async).with(room.id)
      authed_post('/api/v1/graphql', query: query(id: record.id))
    end
  end

  describe "error" do
    it "does not delete a playlist record belonging to another user" do
      record = create(:room_playlist_record, user: create(:user))

      authed_post('/api/v1/graphql', query: query(id: record.id))
      data = json_body.dig(:data, :deleteRoomPlaylistRecord)

      expect(data[:errors]).to_not be_empty
      expect(RoomPlaylistRecord.find_by(id: record.id)).to be_present
    end
  end
end
