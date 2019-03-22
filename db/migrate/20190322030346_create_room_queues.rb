class CreateRoomQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :room_queues, id: :uuid do |t|
      t.references :room
      t.references :song
      t.references :user
      t.integer :order
      t.timestamps
    end
  end
end
