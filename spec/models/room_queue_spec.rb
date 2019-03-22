require 'rails_helper'

RSpec.describe RoomQueue, type: :model do
  it "it can belong to a room, song and user" do
    song = create(:song)
    room = create(:room)
    user = create(:user)

    expect do
      RoomQueue.create!(song: song, room: room, user: user)
    end.to change(RoomQueue, :count).by(1)
  end
end
