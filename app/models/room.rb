class Room < ApplicationRecord
  has_many :users
  has_many :songs
end
