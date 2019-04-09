class RenameRoomSongsToRoomSongs < ActiveRecord::Migration[5.2]
  def change
    rename_table :room_songs, :room_songs
  end
end
