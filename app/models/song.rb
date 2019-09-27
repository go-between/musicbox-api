class Song < ApplicationRecord
  validates :youtube_id, presence: true
  has_many :user_library_records
  has_many :users, through: :user_library_records
end
