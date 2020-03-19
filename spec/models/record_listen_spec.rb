# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordListen, type: :model do
  describe "relationships" do
    it "can belong to a record, song and user" do
      record = create(:room_playlist_record)
      song = create(:song)
      user = create(:user)

      listen = described_class.create!(room_playlist_record: record, song: song, user: user)

      expect(listen.reload.room_playlist_record).to eq(record)
      expect(listen.reload.song).to eq(song)
      expect(listen.reload.user).to eq(user)
    end
  end
end
