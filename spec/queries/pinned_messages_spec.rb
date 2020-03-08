# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messages Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Messages($songId: ID!) {
        pinnedMessages(songId: $songId) {
          id
          message
          pinned
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
  let(:other_room) { create(:room) }
  let(:song) { create(:song) }
  let(:other_song) { create(:song) }
  let(:user1) { create(:user, active_room: room) }
  let(:user2) { create(:user, active_room: room) }

  it "retrieves pinned messages" do
    msg1 = create(:message, room: room, song: song, user: user1, pinned: true)
    msg2 = create(:message, room: room, song: song, user: user2, pinned: true)
    create(:message, room: room, song: song, user: user1, pinned: false)
    create(:message, room: room, song: other_song, user: user2, pinned: true)
    create(:message, room: other_room, song: song, user: user1, pinned: true)

    graphql_request(
      query: query,
      variables: { songId: song.id },
      user: user1
    )

    message_ids = json_body.dig(:data, :pinnedMessages).map { |m| m[:id] }
    expect(message_ids).to match_array([msg1.id, msg2.id])
  end
end
