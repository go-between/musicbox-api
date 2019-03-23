class AddIndexToSongs < ActiveRecord::Migration[5.2]
  def change
    add_index(:songs, :youtube_id)
  end
end
