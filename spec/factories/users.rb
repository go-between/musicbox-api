FactoryBot.define do
  factory :user do
    email { "anime-turtle-#{SecureRandom.uuid}@myspace.com" }
    password { 'hunter2' }
  end
end
