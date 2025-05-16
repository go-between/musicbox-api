# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messages Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Messages($from: DateTime, $to: DateTime) {
        messages(from: $from, to: $to) {
          id
          message
          room {
            id
          }
          user {
            id
          }
          roomPlaylistRecord {
            id
          }
          song {
            id
          }
        }
      }
    )
  end

  let(:room) { create(:room) }
  let(:user) { create(:user, active_room: room) }
  let(:user2) { create(:user, active_room: room) }
  let(:room_playlist_record1) { create(:room_playlist_record, room: room, song: create(:song)) }
  let(:room_playlist_record2) { create(:room_playlist_record, room: room, song: create(:song)) }

  let!(:message1) do
    create(
      :message,
      pinned: false,
      room: room,
      user: user,
      created_at: 5.hours.ago,
      room_playlist_record: room_playlist_record1,
      song: room_playlist_record1.song
    )
  end
  let!(:message2) do
    create(
      :message,
      room: room,
      user: user2,
      created_at: 3.hours.ago,
      room_playlist_record: room_playlist_record2,
      song: room_playlist_record2.song
    )
  end

  let!(:message3) { create(:message, room: room, user: user, created_at: 1.hour.ago) }
  # rubocop:disable RSpec/LetSetup
  let!(:other_message) { create(:message, room: create(:room), user: user2, created_at: 3.hours.ago) }
  # rubocop:enable RSpec/LetSetup

  describe "query" do
    it "returns ordered messages for the user's active room" do
      graphql_request(query: query, user: user)

      expect(json_body.dig(:data, :messages).size).to eq(3)
      message1_body = json_body.dig(:data, :messages, 0)
      expect(message1_body[:id]).to eq(message1.id)
      expect(message1_body.dig(:roomPlaylistRecord, :id)).to eq(room_playlist_record1.id)
      expect(message1_body.dig(:song, :id)).to eq(room_playlist_record1.song.id)
      expect(message1_body.dig(:room, :id)).to eq(room.id)
      expect(message1_body.dig(:user, :id)).to eq(user.id)

      message2_body = json_body.dig(:data, :messages, 1)
      expect(message2_body[:id]).to eq(message2.id)
      expect(message2_body.dig(:roomPlaylistRecord, :id)).to eq(room_playlist_record2.id)
      expect(message2_body.dig(:song, :id)).to eq(room_playlist_record2.song.id)
      expect(message2_body.dig(:room, :id)).to eq(room.id)
      expect(message2_body.dig(:user, :id)).to eq(user2.id)

      message3_body = json_body.dig(:data, :messages, 2)
      expect(message3_body[:id]).to eq(message3.id)
      expect(message3_body[:roomPlaylistRecord]).to be_nil
      expect(message3_body.dig(:room, :id)).to eq(room.id)
      expect(message3_body.dig(:user, :id)).to eq(user.id)
    end

    it "returns no messages if the user is not in an active room" do
      user.update!(active_room_id: nil)
      graphql_request(query: query, user: user)

      expect(json_body.dig(:data, :messages)).to be_empty
    end
  end

  describe "filtering" do
    it "returns messages after the specified datetime" do
      graphql_request(query: query, variables: { from: 4.hours.ago }, user: user)

      message_ids = json_body.dig(:data, :messages).map { |m| m[:id] }
      expect(message_ids).to contain_exactly(message2.id, message3.id)
    end

    it "returns messages before the specified datetime" do
      graphql_request(query: query, variables: { to: 2.hours.ago }, user: user)

      message_ids = json_body.dig(:data, :messages).map { |m| m[:id] }
      expect(message_ids).to contain_exactly(message1.id, message2.id)
    end

    it "returns messages between the specified datetimes" do
      graphql_request(query: query, variables: { from: 4.hours.ago, to: 2.hours.ago }, user: user)

      message_ids = json_body.dig(:data, :messages).map { |m| m[:id] }
      expect(message_ids).to contain_exactly(message2.id)
    end
  end
end
