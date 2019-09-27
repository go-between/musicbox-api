class RenameUserLibrarySongs < ActiveRecord::Migration[5.2]
  def change
    rename_table :user_library_songs, :user_library_records
  end
end
