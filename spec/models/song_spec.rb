require 'rails_helper'

RSpec.describe Song, type: :model do
  it "can have many users" do
    room = Room.create!(name: "Hatch")
    user1 = User.create!(name: "Dan", room: room)
    user2 = User.create!(name: "Truman", room: room)
    song = Song.create!(name: "Whats my age again?", room: room)
    song.users << user1
    song.users << user2
    song.save!
    expect(song.users).to match_array([user1, user2])
  end
end
