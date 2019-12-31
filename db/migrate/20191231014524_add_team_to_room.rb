class AddTeamToRoom < ActiveRecord::Migration[6.0]
  def change
    add_column :rooms, :team_id, :uuid
  end
end
