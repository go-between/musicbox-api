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
    just_finished = current_record.present?
    update!(current_record: nil, playing_until: nil, waiting_songs: false)

    return unless just_finished

    BroadcastNowPlayingWorker.perform_async(self.id)
    BroadcastPlaylistWorker.perform_async(self.id)
  end
end
