# frozen_string_literal: true

FactoryBot.define do
  factory :room_playlist_record do
    room
    song
    user
    order { 1 }
    play_state { 'waiting' }
  end
end
