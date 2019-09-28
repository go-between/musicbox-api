class RoomPlaylistRecord < ApplicationRecord
  belongs_to :room
  belongs_to :song
  belongs_to :user

  enum play_state: {
    waiting: "waiting",
    playing: "playing",
    finished: "finished"
  }
end
