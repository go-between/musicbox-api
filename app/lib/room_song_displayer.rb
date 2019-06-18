class RoomSongDisplayer
  attr_reader :room_id

  def initialize(room_id)
    @room_id = room_id
  end

  def now_playing
    RoomSong.find_by(room_id: room_id, play_state: "playing")
  end

  def up_next
    RoomSong.where(
      room_id: room_id,
      user_id: next_user,
      play_state: "waiting"
    ).order(:order).first
  end

  def waiting
    ordered_waiting_songs = []
    waiting_songs = RoomSong.where(room_id: room_id, play_state: "waiting")

    waiting_user_rotation.each_with_index do |user_id, idx|
      user_waiting_songs = waiting_songs.where(user_id: user_id).order(:order)
      user_waiting_songs.each_with_index do |song, song_idx|
        ordered_waiting_songs[idx + (waiting_user_rotation.size * song_idx)] = song
      end
    end

    ordered_waiting_songs.compact
  end

  # def finished
  #   # [RoomSong]
  # end

  private

  def next_user
    return user_rotation.first unless now_playing_user
    next_user_index = user_rotation.find_index(now_playing_user) + 1
    next_user_index = 0 if next_user_index >= user_rotation.size
    user_rotation[next_user_index]
  end

  def waiting_user_rotation
    next_user_index = user_rotation.find_index(next_user)
    user_rotation[next_user_index..-1] + user_rotation[0...next_user_index]
  end

  def now_playing_user
    now_playing&.user_id
  end

  def room
    @room ||= Room.find(room_id)
  end

  def user_rotation
    room.user_rotation
  end

end
