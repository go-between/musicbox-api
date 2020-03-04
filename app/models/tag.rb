# frozen_string_literal: true

class Tag < ApplicationRecord
  validates :name, presence: true

  belongs_to :user
  has_many :tag_songs
  has_many :songs, through: :tag_songs
end
