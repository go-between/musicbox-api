# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Playlist Record Abandon", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation {
        roomPlaylistRecordAbandon(input: {}) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe "success" do
    it "Updates the room to no longer be playing" do
      record = create(:room_playlist_record, user: current_user)
      room = create(:room, current_record: record, playing_until: 1.hour.from_now)
      current_user.update!(active_room: room)

      graphql_request(
        query: query,
        user: current_user
      )

      expect(json_body.dig(:data, :roomPlaylistRecordAbandon, :errors)).to be_empty
      expect(room.reload.playing_until).to be_past
    end
  end

  describe "error" do
    it "Does nothing if user is not in a room" do
      record = create(:room_playlist_record, user: current_user)
      room = create(:room, current_record: record, playing_until: 1.hour.from_now)

      graphql_request(
        query: query,
        user: current_user
      )

      expect(json_body.dig(:data, :roomPlaylistRecordAbandon, :errors)).to include("Not in active room")
      expect(room.reload.playing_until).to be_future
    end

    it "Does nothing if there is no current record" do
      room = create(:room, current_record: nil, playing_until: 1.hour.from_now)
      current_user.update!(active_room: room)

      graphql_request(
        query: query,
        user: current_user
      )

      expect(json_body.dig(:data, :roomPlaylistRecordAbandon, :errors)).to include("No current record")
      expect(room.reload.playing_until).to be_future
    end

    it "Does nothing if the user does not own the current record" do
      other_user = create(:user)
      record = create(:room_playlist_record, user: other_user)
      room = create(:room, current_record: record, playing_until: 1.hour.from_now)
      current_user.update!(active_room: room)

      graphql_request(
        query: query,
        user: current_user
      )

      expect(json_body.dig(:data, :roomPlaylistRecordAbandon, :errors)).to include("User does not own current song")
      expect(room.reload.playing_until).to be_future
    end
  end
end
