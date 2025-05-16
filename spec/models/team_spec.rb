# frozen_string_literal: true

require "rails_helper"

RSpec.describe Team, type: :model do
  describe "relationships" do
    let(:owner) { create(:user) }

    it "belongs to an owner" do
      team = described_class.create!(owner: owner)
      expect(team.owner).to eq(owner)
    end

    it "may have many users" do
      user1 = create(:user)
      user2 = create(:user)

      team = described_class.create!(owner: owner)
      team.users << user1
      team.users << user2

      expect(team.reload.users).to contain_exactly(user1, user2)
    end

    it "may have many rooms" do
      team = described_class.create!(owner: owner)
      room1 = create(:room, team: team)
      room2 = create(:room, team: team)

      expect(team.reload.rooms).to contain_exactly(room1, room2)
    end
  end
end
