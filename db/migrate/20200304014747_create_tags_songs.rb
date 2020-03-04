class CreateTagsSongs < ActiveRecord::Migration[6.0]
  def change
    create_table :tags_songs, id: :uuid do |t|
      t.uuid :tag_id
      t.uuid :song_id

      t.timestamps
      t.index :tag_id
      t.index :song_id
    end
  end
end
