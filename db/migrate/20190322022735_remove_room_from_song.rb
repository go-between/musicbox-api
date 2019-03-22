class RemoveRoomFromSong < ActiveRecord::Migration[5.2]
  def change
    remove_column(:songs, :room_id)
  end
end
