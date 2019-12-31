# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Room, type: :model do
  let(:room) { described_class.create!(team: create(:team)) }

  describe 'relationships' do
    it 'has many playlist records' do
      record1 = create(:room_playlist_record, room: room)
      record2 = create(:room_playlist_record, room: room)
      record3 = create(:room_playlist_record, room: room)

      expect(room.reload.room_playlist_records).to match_array([record1, record2, record3])
    end

    it 'has many songs' do
      song1 = create(:song)
      song2 = create(:song)
      create(:room_playlist_record, room: room, song: song1)
      create(:room_playlist_record, room: room, song: song2)
      create(:room_playlist_record, room: room, song: song2)

      expect(room.reload.songs).to match_array([song1, song2, song2])
    end

    it 'has many users' do
      user1 = create(:user, room: room)
      user2 = create(:user, room: room)

      expect(room.reload.users).to match_array([user1, user2])
    end

    it 'has one current record' do
      record = create(:room_playlist_record, room: room)
      room.update!(current_record: record)

      expect(room.current_record).to eq(record)
    end

    it 'has one song' do
      song = create(:song)
      record = create(:room_playlist_record, room: room, song: song)
      room.update!(current_record: record)

      expect(room.current_song).to eq(song)
    end
  end
end
