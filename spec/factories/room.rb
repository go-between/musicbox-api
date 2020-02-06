# frozen_string_literal: true

FactoryBot.define do
  factory :room do
    name { "Banjo Town" }
    current_record { nil }
    playing_until { nil }
    waiting_songs { false }
    team
  end
end
