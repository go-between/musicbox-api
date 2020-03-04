# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "relationships" do
    it "belongs to a user" do
      user = create(:user)
      tag = described_class.create!(name: "the-tag", user: user)

      expect(tag.user).to eq(user)
    end
  end
end
