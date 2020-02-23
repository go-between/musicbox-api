class AddQueueProcessingToRoom < ActiveRecord::Migration[6.0]
  def change
    add_column :rooms, :queue_processing, :boolean, default: false
  end
end
