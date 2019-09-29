# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create Song', type: :request do
  include AuthHelper
  include JsonHelper

  def query(room_id:)
    %(
      mutation {
        joinRoom(input:{
          roomId: "#{room_id}"
        }) {
          room {
            id
          }
          errors
        }
      }
    )
  end

  describe 'success' do
    it 'adds the user to the room' do
      room = create(:room)

      authed_post('/api/v1/graphql', query: query(room_id: room.id))
      data = json_body.dig(:data, :joinRoom)

      expect(data.dig(:room, :id)).to eq(room.id)
      expect(data[:errors]).to be_empty
      expect(current_user.reload.room).to eq(room)
    end

    it 'enqueues a broadcast room worker' do
      room = create(:room)

      expect(BroadcastUsersWorker).to receive(:perform_async).with(room.id)
      authed_post('/api/v1/graphql', query: query(room_id: room.id))
    end
  end

  describe 'error' do
    it 'does not allow a user to join a nonexistant room' do
      current_user.update!(room: nil)
      authed_post('/api/v1/graphql', query: query(room_id: SecureRandom.uuid))
      data = json_body.dig(:data, :joinRoom)

      expect(data[:errors]).not_to be_empty
      expect(current_user.reload.room).to be_nil
    end
  end
end
