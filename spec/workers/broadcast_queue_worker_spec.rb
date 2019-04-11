require 'rails_helper'
RSpec.describe BroadcastQueueWorker, type: :worker do
  let(:started) { Time.zone.now }
  let(:song1) { create(:song) }
  let(:song2) { create(:song) }
  let(:room) { create(:room) }
  let(:user) { create(:user) }
  let(:worker) { BroadcastQueueWorker.new }

  describe "#perform" do
    it "broadcasts the queue" do
      create(:room_song, room: room, song: song1, user: user)
      create(:room_song, room: room, song: song2, user: user)

      expect do
        worker.perform(room.id)
      end.to have_broadcasted_to(room).from_channel(QueuesChannel).with { |msg|
        songs = msg.dig(:data, :roomSongs)

        song1_hash = hash_including(song: hash_including(id: song1.id))
        song2_hash = hash_including(song: hash_including(id: song2.id))
        expect(songs).to match_array([song1_hash, song2_hash])
      }
    end
  end
end
