# frozen_string_literal: true

FactoryBot.define do
  factory :room do
    name { 'Banjo Town' }
    current_record { nil }
  end
end
