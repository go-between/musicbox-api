require 'rails_helper'

RSpec.describe RoomSongDisplayer do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:user_3) { create(:user) }
  let(:room) { create(:room, user_rotation: [user_1.id, user_2.id, user_3.id]) }

  describe "#now_playing" do
    it "should return the song the room is currently playing" do
      room_song_1 = create(:room_song, room: room, play_state: "waiting")
      room_song_2 = create(:room_song, room: room, play_state: "playing")
      room_song_3 = create(:room_song, room: room, play_state: "finished")
      room_song_4 = create(:room_song, room: create(:room), play_state: "playing")

      displayer = RoomSongDisplayer.new(room.id)

      expect(displayer.now_playing).to eq(room_song_2)
    end
  end

  describe "#up_next" do
    it "should return the next song in rooms queue" do
      room_song_1 = create(:room_song, room: room, user: user_1, play_state: "playing")
      room_song_2 = create(:room_song, room: room, user: user_2, play_state: "waiting")
      room_song_3 = create(:room_song, room: room, user: user_3, play_state: "waiting")

      displayer = RoomSongDisplayer.new(room.id)

      expect(displayer.up_next).to eq(room_song_2)
    end

    it "should return to the beginning of the room queues rotation" do
      room_song_1 = create(:room_song, room: room, user: user_1, play_state: "waiting")
      room_song_2 = create(:room_song, room: room, user: user_2, play_state: "waiting")
      room_song_3 = create(:room_song, room: room, user: user_3, play_state: "playing")

      displayer = RoomSongDisplayer.new(room.id)

      expect(displayer.up_next).to eq(room_song_1)
    end
  end

  describe "#waiting" do
    it "should the whole room queue" do
      room_song_1 = create(:room_song, room: room, user: user_1, order: 7, play_state: "finished")
      room_song_2 = create(:room_song, room: room, user: user_2, order: 1, play_state: "playing")
      room_song_3 = create(:room_song, room: room, user: user_3, order: 19, play_state: "waiting")
      room_song_4 = create(:room_song, room: room, user: user_1, order: 8, play_state: "waiting")
      room_song_5 = create(:room_song, room: room, user: user_2, order: 2, play_state: "waiting")
      room_song_6 = create(:room_song, room: room, user: user_3, order: 20, play_state: "waiting")

      displayer = RoomSongDisplayer.new(room.id)

      expect(displayer.waiting).to eq([room_song_3, room_song_4, room_song_5, room_song_6])
    end
  end
end
