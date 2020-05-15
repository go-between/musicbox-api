class AddLibraryRecordIndexes < ActiveRecord::Migration[6.0]
  def change
    add_index :library_records, :created_at
    add_index :library_records, :source
    add_index :songs, :name, name: :song_name_order_index
    add_index :songs, :duration_in_seconds
  end
end
