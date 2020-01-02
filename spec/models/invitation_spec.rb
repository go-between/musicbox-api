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

  describe '#self.token' do
    it 'delegates to a secure random generator' do
      expect(SecureRandom).to receive(:uuid).and_return('fbb586a9-b798-4a31-a634-66d28a661375')
      token = described_class.token
      expect(token).to eq('fbb586a9-b798-4a31-a634-66d28a661375')
    end
  end

  describe 'invitation state' do
    let(:user) { create(:user) }
    let(:team) { create(:team) }
    let(:record) { described_class.create!(inviting_user: user, team: team) }

    it 'may be assigned to a pending state' do
      record.update!(invitation_state: :pending)
      expect(record).to be_pending
    end

    it 'may be assigned an accepted state' do
      record.update!(invitation_state: :accepted)
      expect(record).to be_accepted
    end
  end
end
