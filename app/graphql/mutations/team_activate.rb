# frozen_string_literal: true

module Mutations
  class TeamActivate < Mutations::BaseMutation
    argument :team_id, ID, required: true

    field :team, Types::TeamType, null: true
    field :errors, [String], null: true

    def resolve(team_id:)
      return { team: nil, errors: ["User does not belong to this team"] } unless current_user.teams.exists?(id: team_id)

      previous_team_id = current_user.active_team_id
      current_user.update!(active_team_id: team_id)

      BroadcastTeamWorker.perform_async(previous_team_id) if previous_team_id.present?
      BroadcastTeamWorker.perform_async(team_id)

      {
        team: current_user.active_team,
        errors: []
      }
    end
  end
end
