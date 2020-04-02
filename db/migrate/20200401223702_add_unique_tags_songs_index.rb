class AddUniqueTagsSongsIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :tags_songs, [:tag_id, :song_id], unique: true
  end
end
