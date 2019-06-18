FactoryBot.define do
  factory :room_song do
    room
    song
    user
    order { 1 }
    play_state { "waiting" }
  end
end
