# frozen_string_literal: true

class Tag < ApplicationRecord
  validates :name, presence: true

  belongs_to :user
  has_many :tag_library_records
  has_many :library_records, through: :tag_library_records
end
