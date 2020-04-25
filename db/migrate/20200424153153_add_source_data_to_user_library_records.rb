class AddSourceDataToUserLibraryRecords < ActiveRecord::Migration[6.0]
  def change
    add_column :user_library_records, :from_user_id, :uuid
    add_column :user_library_records, :source, :string
  end
end
