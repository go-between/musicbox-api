class AddGinIndexToSongName < ActiveRecord::Migration[6.0]
  def change
    add_index :songs, :name, using: :gin, order: { name: :gin_trgm_ops }
  end
end
