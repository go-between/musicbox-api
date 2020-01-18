# frozen_string_literal: true

class RoomPlaylist
  attr_reader :room_id

  def initialize(room_id)
    @room_id = room_id
  end

  def generate_playlist
    return [] if user_rotation.blank?

    ordered_waiting_songs = []
    waiting_songs = RoomPlaylistRecord.where(room_id: room_id, play_state: "waiting")

    waiting_user_rotation.each_with_index do |user_id, idx|
      user_waiting_songs = waiting_songs.where(user_id: user_id).order(:order)
      user_waiting_songs.each_with_index do |song, song_idx|
        ordered_waiting_songs[idx + (waiting_user_rotation.size * song_idx)] = song
      end
    end

    ordered_waiting_songs.compact
  end

  private

  def waiting_user_rotation
    next_user_index = user_rotation.find_index(next_user)
    user_rotation[next_user_index..-1] + user_rotation[0...next_user_index]
  end

  def next_user
    return user_rotation.first unless current_record_user_id

    next_user_index = user_rotation.find_index(current_record_user_id) + 1
    next_user_index = 0 if next_user_index >= user_rotation.size
    user_rotation[next_user_index]
  end

  def current_record_user_id
    room.current_record&.user_id
  end

  def room
    return @room if defined? @room

    @room ||= Room.find(room_id)
  end

  def user_rotation
    room.user_rotation
  end
end
