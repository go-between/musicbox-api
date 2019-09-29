# frozen_string_literal: true

class AddRoomToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :room_id, :uuid
  end
end
