# frozen_string_literal: true

class AddIdToSongsUsers < ActiveRecord::Migration[5.2]
  def change
    drop_table :songs_users

    create_table :songs_users, id: :uuid do |t|
      t.uuid :song_id
      t.uuid :user_id
      t.index :song_id
      t.index :user_id
      t.timestamps
    end
  end
end
