# frozen_string_literal: true

require "rails_helper"
RSpec.describe BroadcastRecordListensWorker, type: :worker do
  let(:record) { create(:room_playlist_record) }
  let(:room) { create(:room, current_record: record) }
  let(:worker) { described_class.new }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  describe "#perform" do
    it "broadcasts the record listens for the given record" do
      RecordListen.create!(user: user1, room_playlist_record: record, song: record.song, approval: 1)
      RecordListen.create!(user: user2, room_playlist_record: record, song: record.song, approval: 3)

      expect do
        worker.perform(record.id)
      end.to(have_broadcasted_to(room).from_channel(RecordListensChannel).with do |msg|
        listens = msg.dig(:data, :recordListens)
        expect(listens.size).to eq(2)

        user1_listen = listens.find { |l| l.dig(:user, :id) == user1.id }
        user2_listen = listens.find { |l| l.dig(:user, :id) == user2.id }

        expect(user1_listen[:approval]).to eq(1)
        expect(user2_listen[:approval]).to eq(3)
      end)
    end
  end
end
