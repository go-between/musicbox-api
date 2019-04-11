class CreateRoomQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :room_queues, id: :uuid do |t|
      t.references :room, type: :uuid
      t.references :song, type: :uuid
      t.references :user, type: :uuid
      t.integer :order
      t.timestamps
    end
  end
end
