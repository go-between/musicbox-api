# frozen_string_literal: true

class RenameRoomPlaylistSongs < ActiveRecord::Migration[5.2]
  def change
    rename_table :room_playlist_songs, :room_playlist_records
  end
end
