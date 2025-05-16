# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoomPlaylistRecord, type: :model do
  let(:song) { create(:song) }
  let(:room) { create(:room) }
  let(:user) { create(:user) }

  describe "relationships" do
    it "can belong to a room, song and user" do
      record = described_class.create!(song: song, room: room, user: user)

      expect(record.reload.song).to eq(song)
      expect(record.reload.room).to eq(room)
      expect(record.reload.user).to eq(user)
    end

    it "has many record listens" do
      record = described_class.create!(song: song, room: room, user: user)

      l1 = RecordListen.create!(room_playlist_record: record, song: song, user: create(:user))
      l2 = RecordListen.create!(room_playlist_record: record, song: song, user: create(:user))
      l3 = RecordListen.create!(room_playlist_record: record, song: song, user: create(:user))

      expect(record.reload.record_listens).to contain_exactly(l1, l2, l3)
    end
  end

  describe "methods" do
    let(:record) do
      described_class.create!(song: song, room: room, user: user)
    end

    it "may have an order" do
      record.update!(order: 4)

      expect(record.order).to eq(4)
    end

    it "may be assigned a waiting state" do
      record.update!(play_state: :waiting)
      expect(record).to be_waiting
    end

    it "may be assigned a played state" do
      record.update!(play_state: :played)
      expect(record).to be_played
    end
  end
end
