# frozen_string_literal: true

class Room < ApplicationRecord
  validates :name, presence: true

  has_many :users, foreign_key: :active_room_id
  has_many :room_playlist_records
  has_many :songs, through: :room_playlist_records
  belongs_to :current_record, foreign_key: :current_record_id, class_name: "RoomPlaylistRecord", optional: true
  has_one :current_song, through: :current_record, source: :song
  belongs_to :team

  def idle!
    update!(
      current_record: nil,
      playing_until: nil,
      queue_processing: false,
      waiting_songs: false
    )
  end

  def playing_record!(record)
    update!(
      current_record: record,
      playing_until: playing_until_datetime(record),
      queue_processing: false
    )
  end

  private

  def playing_until_datetime(record)
    record.song.duration_in_seconds.seconds.from_now
  end
end
