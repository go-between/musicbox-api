# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibraryRecord, type: :model do
  let(:song) { create(:song) }
  let(:user) { create(:user) }

  describe "relationships" do
    it "can belong to a song and user" do
      record = described_class.create!(song: song, user: user)

      expect(record.reload.song).to eq(song)
      expect(record.reload.user).to eq(user)
    end

    it "has many tags" do
      record = described_class.create!(song: song, user: user)

      tag1 = create(:tag, user: user)
      tag2 = create(:tag, user: user)

      record.tags << tag1
      record.tags << tag2

      expect(record.tags).to match_array([tag1, tag2])
    end
  end
end
