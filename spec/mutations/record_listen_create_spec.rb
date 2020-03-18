# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Record Listen Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation RecordListen($recordId: ID!, $approval: Int!) {
        recordListenCreate(input:{
          recordId: $recordId,
          approval: $approval
        }) {
          recordListen {
            id
          }
          errors
        }
      }
    )
  end

  let(:record) { create(:room_playlist_record) }
  let(:room) { create(:room, current_record: record) }
  let(:current_user) { create(:user, active_room: room) }

  describe "success" do
    it "creates a record listen" do
      expect do
        graphql_request(
          query: query,
          user: current_user,
          variables: { recordId: record.id, approval: 1 }
        )
      end.to change(RecordListen, :count).by(1)

      listen_id = json_body.dig(:data, :recordListenCreate, :recordListen, :id)
      listen = RecordListen.find(listen_id)

      expect(listen.room_playlist_record).to eq(record)
      expect(listen.song).to eq(record.song)
      expect(listen.user).to eq(current_user)
      expect(listen.approval).to eq(1)
    end

    it "updates an existing record listen" do
      listen = RecordListen.create!(room_playlist_record: record, song: record.song, user: current_user, approval: 0)

      expect do
        graphql_request(
          query: query,
          user: current_user,
          variables: { recordId: record.id, approval: 3 }
        )
      end.not_to change(RecordListen, :count)

      listen_id = json_body.dig(:data, :recordListenCreate, :recordListen, :id)
      expect(listen_id).to eq(listen.id)
      expect(listen.reload.approval).to eq(3)
    end
  end
end
