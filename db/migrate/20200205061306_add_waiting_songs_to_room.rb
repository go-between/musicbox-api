class AddWaitingSongsToRoom < ActiveRecord::Migration[6.0]
  def change
    add_column :rooms, :waiting_songs, :boolean
  end
end
