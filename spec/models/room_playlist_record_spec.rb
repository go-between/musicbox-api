# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RoomPlaylistRecord, type: :model do
  describe 'relationships' do
    it 'can belong to a room, song and user' do
      song = create(:song)
      room = create(:room)
      user = create(:user)

      record = described_class.create!(song: song, room: room, user: user)

      expect(record.reload.song).to eq(song)
      expect(record.reload.room).to eq(room)
      expect(record.reload.user).to eq(user)
    end
  end

  describe 'methods' do
    let(:record) do
      song = create(:song)
      room = create(:room)
      user = create(:user)

      described_class.create!(song: song, room: room, user: user)
    end

    it 'may have an order' do
      record.update!(order: 4)

      expect(record.order).to eq(4)
    end

    it 'may be assigned a waiting state' do
      record.update!(play_state: :waiting)
      expect(record).to be_waiting
    end

    it 'may be assigned a played state' do
      record.update!(play_state: :played)
      expect(record).to be_played
    end
  end
end
