FactoryBot.define do
  factory :room do
    name { 'Banjo Town' }
    current_song { create(:song) }
    current_song_start { Time.zone.now }
  end
end
