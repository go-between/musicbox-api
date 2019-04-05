# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Join Room", type: :request do
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
            name
          }
          errors
        }
      }
    )
  end

  let(:room) { create(:room) }

  it "The current user may join a room" do
    authed_post('/api/v1/graphql', query: query(room_id: room.id))
    data = json_body.dig(:data, :joinRoom)

    expect(data.dig(:room, :id)).to eq(room.id)
    expect(current_user.reload.room).to eq(room)
  end

  context "when missing required attributes" do
    it "fails to join non-existent room" do
      current_user.update!(room: room)
      authed_post('/api/v1/graphql', query: query(room_id: SecureRandom.uuid))
      data = json_body.dig(:data, :joinRoom)

      expect(data[:room]).to be_nil
      expect(data[:errors]).to match_array(include("does not exist"))
      expect(current_user.reload.room).to eq(room)
    end
  end
end
