# frozen_string_literal: true

class AddPlayStateAndPlayedAtToRoomSongs < ActiveRecord::Migration[5.2]
  def change
    add_column :room_songs, :play_state, :string
    add_column :room_songs, :played_at, :datetime
    add_index :room_songs, :play_state
  end
end
