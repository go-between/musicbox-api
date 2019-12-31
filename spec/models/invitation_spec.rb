# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe 'relationships' do
    it 'belongs to an inviting user and a team' do
      user = create(:user)
      team = create(:team)
      invitation = described_class.create!(inviting_user: user, team: team)

      expect(invitation.inviting_user).to eq(user)
      expect(invitation.team).to eq(team)
    end
  end
end
