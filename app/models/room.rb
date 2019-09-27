class Room < ApplicationRecord
  has_many :users
  has_many :room_playlist_records
  has_many :songs, through: :room_playlist_records
  belongs_to :current_song, foreign_key: :current_song_id, class_name: "Song", optional: true
end
