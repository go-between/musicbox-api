# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Song, type: :model do
  let(:song) { described_class.create!(youtube_id: 'abcd') }

  describe 'relationships' do
    it 'has many library records' do
      lib1 = create(:user_library_record, song: song)
      lib2 = create(:user_library_record, song: song)

      expect(song.reload.user_library_records).to match_array([lib1, lib2])
    end

    it 'has many users' do
      user1 = create(:user)
      user2 = create(:user)

      create(:user_library_record, song: song, user: user1)
      create(:user_library_record, song: song, user: user2)
      create(:user_library_record, song: song, user: user2)

      expect(song.reload.users).to match_array([user1, user2, user2])
    end
  end
end
