FactoryBot.define do
  factory :room_song do
    room
    song
    user
    order { 1 }
  end
end
