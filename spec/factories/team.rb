# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    name { 'Fine Musical Folks' }
    owner { create(:user) }
  end
end
