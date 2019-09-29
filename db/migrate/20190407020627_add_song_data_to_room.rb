# frozen_string_literal: true

class AddSongDataToRoom < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :current_song_id, :uuid
    add_column :rooms, :current_song_start, :datetime
  end
end
