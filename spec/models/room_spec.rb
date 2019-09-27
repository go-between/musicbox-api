require 'rails_helper'

RSpec.describe Room, type: :model do
  let(:room) { Room.create! }

  describe "relationships" do
    it "has many playlist records" do
      record1 = create(:room_playlist_record, room: room)
      record2 = create(:room_playlist_record, room: room)
      record3 = create(:room_playlist_record, room: room)

      expect(room.reload.room_playlist_records).to match_array([record1, record2, record3])
    end

    it "has many songs" do
      song1 = create(:song)
      song2 = create(:song)
      create(:room_playlist_record, room: room, song: song1)
      create(:room_playlist_record, room: room, song: song2)
      create(:room_playlist_record, room: room, song: song2)

      expect(room.reload.songs).to match_array([song1, song2, song2])
    end

    it "has many users" do
      user1 = create(:user, room: room)
      user2 = create(:user, room: room)

      expect(room.reload.users).to match_array([user1, user2])
    end

    it "it has one current song" do
      start_time = Time.zone.now
      song = create(:song)
      room.update!(current_song: song, current_song_start: start_time)

      expect(room.current_song).to eq(song)
      expect(room.current_song_start).to eq(start_time)
    end
  end
end
