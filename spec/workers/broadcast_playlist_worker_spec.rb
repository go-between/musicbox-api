# frozen_string_literal: true

require 'rails_helper'
RSpec.describe BroadcastPlaylistWorker, type: :worker do
  let(:played_at) { Time.zone.now }
  let(:room) { create(:room) }
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  def create_record(user, song, order)
    create(
      :room_playlist_record,
      user: user,
      song: song,
      room: room,
      play_state: 'waiting',
      order: order
    )
  end

  describe '#perform' do
    it 'broadcasts a playlist interleaved by user rotation and record order' do
      # For user 1
      user1 = create(:user, name: 'User 1')

      user1_song1 = create(:song, name: 'Song 1')
      user1_record1 = create_record(user1, user1_song1, 1)

      user1_song2 = create(:song, name: 'Song 2')
      user1_record2 = create_record(user1, user1_song2, 2)

      # For user 2
      user2 = create(:user, name: 'User 2')

      user2_song1 = create(:song, name: 'Song 3')
      user2_record1 = create_record(user2, user2_song1, 1)

      # For user 3
      user3 = create(:user, name: 'User 3')

      user3_song1 = create(:song, name: 'Song 4')
      user3_record1 = create_record(user3, user3_song1, 1)

      user3_song2 = create(:song, name: 'Song 5')
      user3_record2 = create_record(user3, user3_song2, 2)

      user3_song3 = create(:song, name: 'Song 6')
      user3_record3 = create_record(user3, user3_song3, 3)

      room.update!(user_rotation: [user1.id, user2.id, user3.id])

      expect do
        worker.perform(room.id)
      end.to(have_broadcasted_to(room).from_channel(QueuesChannel).with do |msg|
        songs = msg.dig(:data, :roomPlaylist)

        expect(songs.dig(0, :id)).to eq(user1_record1.id)
        expect(songs.dig(0, :song, :id)).to eq(user1_song1.id)

        expect(songs.dig(1, :id)).to eq(user2_record1.id)
        expect(songs.dig(1, :song, :id)).to eq(user2_song1.id)

        expect(songs.dig(2, :id)).to eq(user3_record1.id)
        expect(songs.dig(2, :song, :id)).to eq(user3_song1.id)

        expect(songs.dig(3, :id)).to eq(user1_record2.id)
        expect(songs.dig(3, :song, :id)).to eq(user1_song2.id)

        expect(songs.dig(4, :id)).to eq(user3_record2.id)
        expect(songs.dig(4, :song, :id)).to eq(user3_song2.id)

        expect(songs.dig(5, :id)).to eq(user3_record3.id)
        expect(songs.dig(5, :song, :id)).to eq(user3_song3.id)
      end)
    end
  end
end
