require 'rails_helper'

RSpec.describe RoomSong, type: :model do
  it "it can belong to a room, song and user" do
    song = create(:song)
    room = create(:room)
    user = create(:user)

    expect do
      RoomSong.create!(song: song, room: room, user: user)
    end.to change(RoomSong, :count).by(1)
  end
end
