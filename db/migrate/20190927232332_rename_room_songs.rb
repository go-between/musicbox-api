class RenameRoomSongs < ActiveRecord::Migration[5.2]
  def change
    rename_table :room_songs, :room_playlist_songs
  end
end
