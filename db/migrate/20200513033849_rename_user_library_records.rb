class RenameUserLibraryRecords < ActiveRecord::Migration[6.0]
  def change
    rename_table :user_library_records, :library_records
  end
end
