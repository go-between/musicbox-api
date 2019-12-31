class UpdateRoomForUser < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :room_id, :active_room_id
  end
end
