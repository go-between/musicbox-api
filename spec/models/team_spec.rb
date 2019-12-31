# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team, type: :model do
  describe 'relationships' do
    let(:owner) { create(:user) }

    it 'belongs to an owner' do
      team = described_class.create!(owner: owner)
      expect(team.owner).to eq(owner)
    end

    it 'may have many users' do
      user1 = create(:user)
      user2 = create(:user)

      team = described_class.create!(owner: owner)
      team.users << user1
      team.users << user2

      expect(team.reload.users).to match_array([user1, user2])
    end
  end
end
