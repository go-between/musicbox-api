class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email
      t.string :name
      t.string :google_id

      t.index :email
      t.timestamps
    end
  end
end
