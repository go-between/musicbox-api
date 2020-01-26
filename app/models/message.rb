# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :room_playlist_record, optional: true
  belongs_to :room
  belongs_to :user
end
