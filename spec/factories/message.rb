# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    message { "Hey Friend" }
    pinned { false }
    created_at { Time.zone.now }
    room_playlist_record { nil }
    room
    song { nil }
    user
  end
end
