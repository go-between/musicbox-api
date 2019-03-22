class Song < ApplicationRecord
  belongs_to :room
  has_and_belongs_to_many :users
end
