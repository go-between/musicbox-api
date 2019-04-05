class AddRoomAndNameToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :name, :string
    add_column :users, :room_id, :uuid
    add_index :users, :room_id
  end
end
