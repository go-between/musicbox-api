class Room < ApplicationRecord
  has_many :users
  has_many :enqueues, foreign_key: :room_id, class_name: "RoomQueue"
  has_many :enqueued_songs, through: :enqueues, source: :song
end
