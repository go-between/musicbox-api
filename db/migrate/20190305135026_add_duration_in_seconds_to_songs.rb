# frozen_string_literal: true

class AddDurationInSecondsToSongs < ActiveRecord::Migration[5.2]
  def change
    add_column :songs, :duration_in_seconds, :integer
  end
end
