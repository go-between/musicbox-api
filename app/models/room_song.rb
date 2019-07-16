class RoomSong < ApplicationRecord
  belongs_to :room
  belongs_to :song
  belongs_to :user

  scope :interleaved_by_oldest_user, -> { order(:created_at).group_by(&:user_id).values.flatten }

  enum play_state: {
    waiting: "waiting",
    playing: "playing",
    finished: "finished"
  }
end
