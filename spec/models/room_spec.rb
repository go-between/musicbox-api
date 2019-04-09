require 'rails_helper'

RSpec.describe RoomQueue, type: :model do
  it "it has an assocation to the current song" do
    start_time = Time.zone.now
    song = create(:song)
    room = create(:room, current_song: song, current_song_start: start_time)

    expect(room.current_song).to eq(song)
    expect(room.current_song_start).to eq(start_time)
  end
end
