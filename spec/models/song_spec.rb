require 'rails_helper'

RSpec.describe Song, type: :model do
  it "can have many users" do
    song = create(:song)
    user1 = create(:user)
    user2 = create(:user)
    song.users << user1
    song.users << user2

    expect(song.reload.users).to match_array([user1, user2])
  end
end
