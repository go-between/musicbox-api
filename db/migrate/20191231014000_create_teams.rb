class CreateTeams < ActiveRecord::Migration[6.0]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name
      t.uuid :owner_id

      t.timestamps
    end
  end
end
