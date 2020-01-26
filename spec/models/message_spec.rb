# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, type: :model do
  describe "relationships" do
    let(:room) { create(:room) }
    let(:user) { create(:user) }
    let(:room_playlist_record) { create(:room_playlist_record, room: room, user: user) }

    it "may belong to a room, user, and playlist record" do
      message = described_class.create!(
        message: "hi",
        room_playlist_record: room_playlist_record,
        room: room,
        user: user
      )

      expect(message.room_playlist_record).to eq(room_playlist_record)
      expect(message.room).to eq(room)
      expect(message.user).to eq(user)
    end

    it "does not require a room room_playlist_record" do
      message = described_class.create!(message: "hi", room: room, user: user)

      expect(message).to be_persisted
      expect(message.room_playlist_record).to be_nil
    end
  end
end
