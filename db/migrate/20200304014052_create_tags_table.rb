class CreateTagsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.uuid :user_id
      t.string :name

      t.timestamps
      t.index :user_id
    end
  end
end
