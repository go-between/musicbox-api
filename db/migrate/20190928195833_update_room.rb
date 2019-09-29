class UpdateRoom < ActiveRecord::Migration[5.2]
  def change
    rename_column :rooms, :current_song_id, :current_record_id
    remove_column :rooms, :current_song_start
  end
end
