# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserLibraryRecord, type: :model do
  describe 'relationships' do
    it 'can belong to a song and user' do
      song = create(:song)
      user = create(:user)

      record = described_class.create!(song: song, user: user)

      expect(record.reload.song).to eq(song)
      expect(record.reload.user).to eq(user)
    end
  end
end
