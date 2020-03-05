class AddPinnedToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :pinned, :boolean, default: false
  end
end
