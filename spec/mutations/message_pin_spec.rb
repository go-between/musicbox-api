# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Message Pin", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation MessagePin($messageId: ID!, $pin: Boolean!) {
        messagePin(input: {
          messageId: $messageId,
          pin: $pin
        }) {
          message {
            id
            pinned
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }
  let(:song) { create(:song) }
  let(:message) { create(:message, pinned: false, user: current_user, song: song) }

  describe "success" do
    it "Allows a user to pin a message" do
      graphql_request(query: query, variables: { messageId: message.id, pin: true }, user: current_user)

      expect(message.reload.pinned).to be(true)
      expect(json_body.dig(:data, :messagePin, :message, :id)).to eq(message.id)
      expect(BroadcastPinnedMessagesWorker).to have_enqueued_sidekiq_job(message.room_id, message.song_id)
    end

    it "Noops if a message is already pinned" do
      message.update!(pinned: true)
      graphql_request(query: query, variables: { messageId: message.id, pin: true }, user: current_user)

      expect(message.reload.pinned).to be(true)
      expect(json_body.dig(:data, :messagePin, :message, :id)).to eq(message.id)
      expect(BroadcastPinnedMessagesWorker).to have_enqueued_sidekiq_job(message.room_id, message.song_id)
    end

    it "Allows a user to unpin a message" do
      message.update!(pinned: true)
      graphql_request(query: query, variables: { messageId: message.id, pin: false }, user: current_user)

      expect(message.reload.pinned).to be(false)
      expect(json_body.dig(:data, :messagePin, :message, :id)).to eq(message.id)
      expect(BroadcastPinnedMessagesWorker).to have_enqueued_sidekiq_job(message.room_id, message.song_id)
    end

    it "Noops if a message is already unpinned" do
      graphql_request(query: query, variables: { messageId: message.id, pin: false }, user: current_user)

      expect(message.reload.pinned).to be(false)
      expect(json_body.dig(:data, :messagePin, :message, :id)).to eq(message.id)
      expect(BroadcastPinnedMessagesWorker).to have_enqueued_sidekiq_job(message.room_id, message.song_id)
    end
  end

  describe "failure" do
    it "does not update a message when sent by a different user" do
      user = create(:user)
      graphql_request(query: query, variables: { messageId: message.id, pin: true }, user: user)

      expect(json_body.dig(:data, :messagePin, :errors)).to include("Message must belong to the current user")
      expect(message.reload.pinned).to be(false)
      expect(BroadcastPinnedMessagesWorker).not_to have_enqueued_sidekiq_job
    end
  end
end
