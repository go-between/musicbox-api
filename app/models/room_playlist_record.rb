# frozen_string_literal: true

class RoomPlaylistRecord < ApplicationRecord
  belongs_to :room
  belongs_to :song
  belongs_to :user

  enum play_state: {
    played: 'played',
    waiting: 'waiting'
  }
end
