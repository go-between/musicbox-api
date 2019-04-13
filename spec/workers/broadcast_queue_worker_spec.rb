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

    it "broadcasts a queue of songs interleaved by user age and song order" do
      song1 = create(:song, name: "Song 1")
      song2 = create(:song, name: "Song 2")
      song3 = create(:song, name: "Song 3")
      song4 = create(:song, name: "Song 4")
      song5 = create(:song, name: "Song 5")
      song6 = create(:song, name: "Song 6")
      user1 = create(:user, name: "User 1")
      user2 = create(:user, name: "User 2")
      user3 = create(:user, name: "User 3")
      # user2 is oldest user in the room, so his songs should be in the first cycle
      room_song1 = create(:room_song, room: room, song: song1, user: user2, order: 1) #1
      # even though the room_song for this is older that user1's other song,
      # its ordinality should make it second for user1 in the array
      room_song2 = create(:room_song, room: room, song: song2, user: user1, order: 2) #5
      room_song3 = create(:room_song, room: room, song: song3, user: user3, order: 1) #3
      room_song4 = create(:room_song, room: room, song: song4, user: user1, order: 1) #2
      room_song5 = create(:room_song, room: room, song: song5, user: user3, order: 2) #6
      room_song6 = create(:room_song, room: room, song: song6, user: user2, order: 2) #4

      expect do
        worker.perform(room.id)
      end.to have_broadcasted_to(room).from_channel(QueuesChannel).with { |msg|
        songs = msg.dig(:data, :roomSongs)

        song1_hash = hash_including(song: hash_including(id: song1.id))
        song2_hash = hash_including(song: hash_including(id: song2.id))
        song3_hash = hash_including(song: hash_including(id: song3.id))
        song4_hash = hash_including(song: hash_including(id: song4.id))
        song5_hash = hash_including(song: hash_including(id: song5.id))
        song6_hash = hash_including(song: hash_including(id: song6.id))

        expect(songs).to match_array([
          song1_hash,
          song4_hash,
          song3_hash,
          song6_hash,
          song2_hash,
          song5_hash
        ])
      }
    end
  end
end
