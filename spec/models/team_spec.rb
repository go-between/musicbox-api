# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team, type: :model do
  describe 'relationships' do
    it 'belongs to an owner' do
      owner = create(:user)
      team = described_class.create!(owner: owner)
      expect(team.owner).to eq(owner)
    end
  end
end
