# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "relationships" do
    let(:user) { create(:user) }
    it "belongs to a user" do
      tag = described_class.create!(name: "the-tag", user: user)

      expect(tag.user).to eq(user)
    end

    it "has many songs" do
      tag = described_class.create!(name: "the-tag", user: user)

      song1 = create(:song)
      song2 = create(:song)

      tag.songs << song1
      tag.songs << song2

      expect(tag.songs).to match_array([song1, song2])
    end
  end
end
