# frozen_string_literal: true

class RoomPlaylist
  attr_reader :room

  def initialize(room)
    @room = room
  end

  def generate_playlist
    room.with_lock do
      return [] if user_rotation.blank?

      ordered_waiting_songs = []
      waiting_user_rotation.each_with_index do |user_id, idx|
        waiting_songs_for_user(user_id).each_with_index do |song, song_idx|
          ordered_waiting_songs[idx + (waiting_user_rotation.size * song_idx)] = song
        end
      end

      ordered_waiting_songs.compact
    end
  end

  private

  def waiting_songs
    return @waiting_songs if defined? @waiting_songs

    @waiting_songs = RoomPlaylistRecord.includes(:song, :user).where(room_id: room.id, play_state: "waiting").to_a
  end

  def waiting_songs_for_user(user_id)
    waiting_songs.select { |song| song.user_id == user_id }.sort_by(&:order)
  end

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

  def user_rotation
    room.user_rotation
  end
end
