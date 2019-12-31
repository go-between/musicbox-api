# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { described_class.create!(email: 'test@test.com', password: '123456') }

  describe 'relationships' do
    it 'has many library records' do
      record1 = create(:user_library_record, user: user)
      record2 = create(:user_library_record, user: user)
      record3 = create(:user_library_record, user: user)

      expect(user.reload.user_library_records).to match_array([record1, record2, record3])
    end

    it 'has many songs' do
      song1 = create(:song)
      song2 = create(:song)

      create(:user_library_record, user: user, song: song1)
      create(:user_library_record, user: user, song: song2)
      create(:user_library_record, user: user, song: song2)

      expect(user.reload.songs).to match_array([song1, song2, song2])
    end

    it 'may belong to a room' do
      room = create(:room)
      user.update!(room: room)

      expect(user.room).to eq(room)
    end

    it 'may be part of many teams' do
      team1 = create(:team)
      team2 = create(:team)

      user.teams << team1
      user.teams << team2

      expect(user.reload.teams).to match_array([team1, team2])
    end
  end
end
