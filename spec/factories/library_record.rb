# frozen_string_literal: true

FactoryBot.define do
  factory :library_record do
    song
    user
    source { nil }
  end
end
