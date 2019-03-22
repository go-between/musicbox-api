class User < ApplicationRecord
  belongs_to :room
  has_and_belongs_to_many :songs
end
