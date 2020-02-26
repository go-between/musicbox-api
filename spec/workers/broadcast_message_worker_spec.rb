# frozen_string_literal: true

require "rails_helper"
RSpec.describe BroadcastMessageWorker, type: :worker do
  let(:created_at) { Time.zone.now }
  let(:room) { create(:room) }
  let(:user) { create(:user, name: "Jorm", email: "a@a.a") }
  let(:room_playlist_record) { create(:room_playlist_record) }
  let(:worker) { described_class.new }

  describe "#perform" do
    it "broadcasts a message" do
      message = Message.create!(
        message: "Howdy folks",
        room_playlist_record: room_playlist_record,
        room: room,
        user: user,
        created_at: created_at
      )

      expect do
        worker.perform(room.id, message.id)
      end.to(have_broadcasted_to(room).from_channel(MessageChannel).with do |msg|
        data = msg.dig(:data, :message)
        expect(data[:message]).to eq("Howdy folks")
        expect(data[:createdAt]).to eq(created_at.iso8601)
        expect(data.dig(:roomPlaylistRecord, :song, :name)).to eq(room_playlist_record.song.name)
        expect(data.dig(:user, :name)).to eq("Jorm")
        expect(data.dig(:user, :email)).to eq("a@a.a")
      end)
    end
  end
end
