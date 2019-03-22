require 'rails_helper'

RSpec.describe User, type: :model do
  it "can have many songs" do
    user = create(:user)
    song1 = create(:song, room: user.room)
    song2 = create(:song, room: user.room)
    user.songs << song1
    user.songs << song2

    expect(user.reload.songs).to match_array([song1, song2])
  end
end
