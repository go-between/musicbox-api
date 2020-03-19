class CreateListensTable < ActiveRecord::Migration[6.0]
  def change
    create_table :record_listens, id: :uuid do |t|
      t.uuid :room_playlist_record_id
      t.uuid :song_id
      t.uuid :user_id
      t.integer :approval, default: 0, null: false

      t.timestamps

      t.index :room_playlist_record_id
      t.index :song_id
    end
  end
end
