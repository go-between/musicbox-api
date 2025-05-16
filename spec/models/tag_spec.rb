# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "relationships" do
    let(:user) { create(:user) }

    it "belongs to a user" do
      tag = described_class.create!(name: "the-tag", user: user)

      expect(tag.user).to eq(user)
    end

    it "has many library records" do
      tag = described_class.create!(name: "the-tag", user: user)

      library_record1 = create(:library_record)
      library_record2 = create(:library_record)

      tag.library_records << library_record1
      tag.library_records << library_record2

      expect(tag.library_records).to contain_exactly(library_record1, library_record2)
    end
  end
end
