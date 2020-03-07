class AddSongIdToMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :song_id, :uuid
  end
end
