class TagSong < ApplicationRecord
  self.table_name = "tags_songs"
end

class AllowLibraryRecordToAssociateToTags < ActiveRecord::Migration[6.0]
  def up
    # This is probably very bad practice, but uh...
    add_column :tags_songs, :library_record_id, :uuid
    TagSong.all.each do |tag_song|
      tag = Tag.find(tag_song.tag_id)
      record = LibraryRecord.find_by!(user_id: tag.user_id, song_id: tag_song.song_id)
      tag_song.update!(library_record_id: record.id)
    end

    add_index :tags_songs, :library_record_id
    add_index :tags_songs, [:tag_id, :library_record_id], unique: true
    remove_index :tags_songs, :song_id
    remove_index :tags_songs, [:tag_id, :song_id]
    remove_column :tags_songs, :song_id

    rename_table :tags_songs, :tags_library_records
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
