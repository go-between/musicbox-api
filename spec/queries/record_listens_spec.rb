# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Record Listens Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query RecordListens($recordId: ID!) {
        recordListens(recordId: $recordId) {
          id
          approval
          roomPlaylistRecord {
            id
          }
          song {
            id
          }
          user {
            id
          }
        }
      }
    )
  end

  let(:record) { create(:room_playlist_record) }

  it "retrieves record listens" do
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)
    l1 = RecordListen.create!(room_playlist_record: record, song: record.song, user: user1, approval: 1)
    l2 = RecordListen.create!(room_playlist_record: record, song: record.song, user: user2, approval: 2)
    l3 = RecordListen.create!(room_playlist_record: record, song: record.song, user: user3, approval: 3)

    graphql_request(
      query: query,
      variables: { recordId: record.id },
      user: user1
    )

    listens = json_body.dig(:data, :recordListens).map { |m| { id: m[:id], approval: m[:approval] } }
    expected_listens = [{ id: l1.id, approval: 1 }, { id: l2.id, approval: 2 }, { id: l3.id, approval: 3 }]
    expect(listens).to match_array(expected_listens)
  end
end
