class RoomQueue < ApplicationRecord
  belongs_to :room
  belongs_to :song
  belongs_to :user
end
