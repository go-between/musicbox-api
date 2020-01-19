# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

user1 = User.find_or_initialize_by(email: "a@a.a", name: "Jorm Nightengale")
user1.update!(password: "hunter2")
user2 = User.find_or_initialize_by(email: "b@b.b", name: "Flawn Sprangboot")
user2.update!(password: "hunter2")

team1 = Team.find_or_create_by!(name: "A Cat As Large As A Mountain", owner: user1)
team2 = Team.find_or_create_by!(name: "They Who Wear Green Feet", owner: user2)

user1.teams << team1 unless user1.teams.exists?(id: team1.id)
user1.teams << team2 unless user1.teams.exists?(id: team2.id)

user2.teams << team1 unless user2.teams.exists?(id: team1.id)

Room.find_or_create_by!(name: "Their Shoulders Breach The Clouds", team: team1)
Room.find_or_create_by!(name: "Whose Whiskers Cast Large Shadows", team: team1)
Room.find_or_create_by!(name: "Having Paws Like Boulders", team: team1)

Room.find_or_create_by!(name: "As A Leaf In Spring", team: team2)
Room.find_or_create_by!(name: "When A Frog Is New", team: team2)

song1 = Song.find_or_create_by!(
  name: "GLORYHAMMER - The Siege of Dunkeld (In Hoots We Trust) (Official Lyric Video) | Napalm Records",
  duration_in_seconds: 286,
  youtube_id: "rZ_wNdYgP3w"
)

song2 = Song.find_or_create_by!(
  name: "M83 'Midnight City' Official video",
  duration_in_seconds: 243,
  youtube_id: "dX3k_QDnzHE"
)

song3 = Song.find_or_create_by!(
  name: "Four Tet - Unicorn (Monotrone Remix)",
  duration_in_seconds: 353,
  youtube_id: "QXIB4JGPtmo"
)

user1.songs << song1 unless user1.songs.exists?(id: song1.id)
user1.songs << song2 unless user1.songs.exists?(id: song2.id)

user2.songs << song2 unless user2.songs.exists?(id: song2.id)
user2.songs << song3 unless user2.songs.exists?(id: song3.id)
