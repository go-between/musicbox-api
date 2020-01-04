# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Delete Room Playlist Record', type: :request do
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

  let(:current_user) { create(:user) }

  describe 'success' do
    it 'deletes a room playlist record belonging to the user' do
      record = create(:room_playlist_record, user: current_user)

      graphql_request(
        query: query(id: record.id),
        user: current_user
      )
      data = json_body.dig(:data, :deleteRoomPlaylistRecord)

      expect(data[:errors]).to be_empty
      expect(RoomPlaylistRecord.find_by(id: record.id)).not_to be_present
    end

    it 'enqueues a queue management broadcast worker for the room' do
      room = create(:room)
      record = create(:room_playlist_record, room: room, user: current_user)

      expect(BroadcastPlaylistWorker).to receive(:perform_async).with(room.id)
      graphql_request(
        query: query(id: record.id),
        user: current_user
      )
    end
  end

  describe 'error' do
    it 'does not delete a playlist record belonging to another user' do
      record = create(:room_playlist_record, user: create(:user))

      graphql_request(
        query: query(id: record.id),
        user: current_user
      )
      data = json_body.dig(:data, :deleteRoomPlaylistRecord)

      expect(data[:errors]).not_to be_empty
      expect(RoomPlaylistRecord.find_by(id: record.id)).to be_present
    end
  end
end
