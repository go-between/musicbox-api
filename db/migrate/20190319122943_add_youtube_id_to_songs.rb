# frozen_string_literal: true

class AddYoutubeIdToSongs < ActiveRecord::Migration[5.2]
  def change
    add_column :songs, :youtube_id, :string
  end
end
