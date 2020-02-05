class AddPlayingUntilToRoom < ActiveRecord::Migration[6.0]
  def change
    add_column :rooms, :playing_until, :datetime
    add_index :rooms, :playing_until
  end
end
