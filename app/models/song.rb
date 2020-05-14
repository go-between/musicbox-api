# frozen_string_literal: true

class Song < ApplicationRecord
  validates :youtube_id, presence: true
  has_many :library_records, inverse_of: :song
  has_many :users, through: :library_records
end
