class CreateInvitations < ActiveRecord::Migration[6.0]
  def change
    create_table :invitations, id: :uuid do |t|
      t.string :email
      t.uuid :token
      t.uuid :invited_by_id
      t.uuid :team_id

      t.index :token
      t.timestamps
    end
  end
end
