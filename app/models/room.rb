class Room < ApplicationRecord
  has_many :users
  has_many :enqueues, foreign_key: :room_id, class_name: "RoomQueue"
  has_many :enqueued_songs, through: :enqueues, source: :song
  belongs_to :current_song, foreign_key: :current_song_id, class_name: "Song", optional: true
end
