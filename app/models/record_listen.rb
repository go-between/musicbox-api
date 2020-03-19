# frozen_string_literal: true

class RecordListen < ApplicationRecord
  belongs_to :room_playlist_record
  belongs_to :song
  belongs_to :user
end
