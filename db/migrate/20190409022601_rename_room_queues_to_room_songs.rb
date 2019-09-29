# frozen_string_literal: true

class RenameRoomQueuesToRoomSongs < ActiveRecord::Migration[5.2]
  def change
    rename_table :room_queues, :room_songs
  end
end
