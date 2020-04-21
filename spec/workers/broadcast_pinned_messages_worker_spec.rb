# frozen_string_literal: true

require "rails_helper"
RSpec.describe BroadcastPinnedMessagesWorker, type: :worker do
  let(:room) { create(:room) }
  let(:song) { create(:song) }
  let(:worker) { described_class.new }

  describe "#perform" do
    it "broadcasts all pinned messages" do
      Message.create!(
        message: "Have I ever told you the story of how this song saved my life?",
        room_playlist_record: create(:room_playlist_record, song: song),
        room: room,
        user: create(:user, name: "Jorm", email: "a@a.a"),
        created_at: 2.minute.ago,
        song: song,
        pinned: true
      )
      Message.create!(
        message: "Yes grandpa.",
        room_playlist_record: create(:room_playlist_record, song: song),
        room: room,
        user: create(:user, name: "Flawn", email: "b@b.b"),
        created_at: 1.minutes.ago,
        song: song,
        pinned: true
      )
      Message.create!(
        message: "You all want lunch?",
        room_playlist_record: create(:room_playlist_record, song: song),
        room: room,
        user: create(:user, name: "Flowrn", email: "c@c.c"),
        created_at: 3.minutes.ago,
        song: song,
        pinned: false
      )

      expect do
        worker.perform(room.id, song.id)
      end.to(have_broadcasted_to(room).from_channel(PinnedMessagesChannel).with do |msg|
        data = msg.dig(:data, :pinnedMessages)
        expect(data.size).to eq(2)
        expect(data.first["message"]).to include("Have I ever told you the story")
        expect(data.second["message"]).to eq("Yes grandpa.")
      end)
    end
  end
end
