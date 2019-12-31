class AddActiveTeamToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :active_team_id, :uuid
  end
end
