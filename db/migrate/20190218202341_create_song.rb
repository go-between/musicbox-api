# frozen_string_literal: true

class CreateSong < ActiveRecord::Migration[5.2]
  def change
    create_table :songs, id: :uuid do |t|
      t.string :name
      t.string :url
      t.uuid :room_id

      t.timestamps
    end
  end
end
