class AddInvitedUserNameToInvitation < ActiveRecord::Migration[6.0]
  def change
    add_column :invitations, :name, :string
  end
end
