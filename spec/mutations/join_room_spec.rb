# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create Song', type: :request do
  include AuthHelper
  include GraphQLHelper
  include JsonHelper

  let(:current_user) { create(:user) }

  describe 'success' do
    it 'adds the user to the room' do
      room = create(:room)

      authed_post(
        url: '/api/v1/graphql',
        body: { query: join_room_mutation(room_id: room.id) },
        user: current_user
      )
      data = json_body.dig(:data, :joinRoom)

      expect(data.dig(:room, :id)).to eq(room.id)
      expect(data[:errors]).to be_empty
      expect(current_user.reload.room).to eq(room)
    end

    it 'enqueues a broadcast room worker' do
      room = create(:room)

      expect(BroadcastUsersWorker).to receive(:perform_async).with(room.id)
      authed_post(
        url: '/api/v1/graphql',
        body: { query: join_room_mutation(room_id: room.id) },
        user: current_user
      )
    end
  end

  describe 'error' do
    it 'does not allow a user to join a nonexistant room' do
      current_user.update!(room: nil)
      authed_post(
        url: '/api/v1/graphql',
        body: { query: join_room_mutation(room_id: SecureRandom.uuid) },
        user: current_user
      )
      data = json_body.dig(:data, :joinRoom)

      expect(data[:errors]).not_to be_empty
      expect(current_user.reload.room).to be_nil
    end
  end
end
