class AddStateToInvitation < ActiveRecord::Migration[6.0]
  def change
    add_column :invitations, :invitation_state, :string
  end
end
