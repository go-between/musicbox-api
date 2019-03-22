require 'rails_helper'

RSpec.describe Song, type: :model do
  it "can have many users" do
    song = create(:song)
    user1 = create(:user, room: song.room)
    user2 = create(:user, room: song.room)
    song.users << user1
    song.users << user2

    expect(song.reload.users).to match_array([user1, user2])
  end
end
