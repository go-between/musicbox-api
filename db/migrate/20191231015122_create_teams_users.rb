class CreateTeamsUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :teams_users, id: :uuid do |t|
      t.uuid :team_id
      t.uuid :user_id

      t.index :team_id
      t.index :user_id
      t.timestamps
    end
  end
end
