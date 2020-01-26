class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages, id: :uuid do |t|
      t.string :message
      t.uuid :room_playlist_record_id
      t.uuid :room_id
      t.uuid :user_id
      t.timestamps

      t.index :room_id
      t.index :created_at
    end
  end
end
