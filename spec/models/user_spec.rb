require 'rails_helper'

RSpec.describe User, type: :model do
  it "can have many songs" do
    room = Room.create!(name: "Hatch")
    user = User.create!(name: "Dan", room: room)
    song1 = Song.create!(name: "Whats my age again?", room: room)
    song2 = Song.create!(name: "Damnit", room: room)
    user.songs << song1
    user.songs << song2
    user.save!
    expect(user.songs).to match_array([song1, song2])
  end
end
