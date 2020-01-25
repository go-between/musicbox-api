# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitation Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation MessageCreate($message: String!) {
        messageCreate(input: {
          message: $message
        }) {
          message {
            id
          }
          errors
        }
      }
    )
  end

  let(:room_playlist_record) { create(:room_playlist_record) }
  let(:room) { create(:room, current_record: room_playlist_record) }
  let(:current_user) { create(:user, active_room: room) }

  describe "success" do
    it "creates a new message" do
      graphql_request(query: query, variables: { message: "Heyo" }, user: current_user)
      id = json_body.dig(:data, :messageCreate, :message, :id)

      message = Message.find(id)
      expect(message.room_playlist_record).to eq(room_playlist_record)
      expect(message.room).to eq(room)
      expect(message.user).to eq(current_user)
    end
  end

  describe "failure" do
    it "does not create a message when user is not in a room" do
      current_user.update!(active_room_id: nil)
      expect do
        graphql_request(query: query, variables: { message: "Heyo" }, user: current_user)
      end.to not_change(Message, :count)
    end
  end
end
