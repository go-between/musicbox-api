class Song < ApplicationRecord
  validates :youtube_id, presence: true
  has_many :song_users
  has_many :users, through: :song_users
end
