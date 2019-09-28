class Room < ApplicationRecord
  has_many :users
  has_many :room_playlist_records
  has_many :songs, through: :room_playlist_records
  belongs_to :current_record, foreign_key: :current_record_id, class_name: "RoomPlaylistRecord", optional: true
  has_one :current_song, through: :current_record, source: :song
end
