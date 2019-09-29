# frozen_string_literal: true

class AddUserRotationToRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :user_rotation, :uuid, array: true, default: []
  end
end
