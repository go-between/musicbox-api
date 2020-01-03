# frozen_string_literal: true

module Mutations
  class TeamActivate < Mutations::BaseMutation
    argument :team_id, ID, required: true
    field :errors, [String], null: true

    def resolve(team_id:)
      return { errors: ['User does not belong to this team'] } unless current_user.teams.exists?(id: team_id)

      current_user.update!(active_team_id: team_id)
      { errors: [] }
    end
  end
end
