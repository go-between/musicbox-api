# frozen_string_literal: true

class UpdateSongTable < ActiveRecord::Migration[5.2]
  def change
    add_column :songs, :description, :string
    remove_column :songs, :url
  end
end
