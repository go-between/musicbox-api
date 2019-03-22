require 'rails_helper'

RSpec.describe Song, type: :model do
  it "can have many users" do
    song = create(:song)
    room = create(:room)
    user1 = create(:user, room: room)
    user2 = create(:user, room: room)
    song.users << user1
    song.users << user2

    expect(song.reload.users).to match_array([user1, user2])
  end
end
