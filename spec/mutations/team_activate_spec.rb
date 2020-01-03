# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Team Activate', type: :request do
  include AuthHelper
  include JsonHelper

  def query(team_id:)
    %(
      mutation {
        teamActivate(input:{
          teamId: "#{team_id}"
        }) {
          errors
        }
      }
    )
  end

  let(:team) { create(:team) }
  let(:current_user) { create(:user, teams: [team]) }

  describe 'success' do
    it 'updates the active team for the user' do
      current_user.update!(active_team: nil)

      graphql_request(
        query: query(team_id: team.id),
        user: current_user
      )

      current_user.reload
      expect(current_user.active_team).to eq(team)

      other_team = create(:team)
      current_user.teams << other_team
      graphql_request(
        query: query(team_id: other_team.id),
        user: current_user
      )

      current_user.reload
      expect(current_user.active_team).to eq(other_team)
    end
  end

  describe 'error' do
    it 'does not allow a user to activate a team they are not on' do
      not_their_team = create(:team)
      graphql_request(
        query: query(team_id: not_their_team.id),
        user: current_user
      )

      current_user.reload
      expect(current_user.active_team).to be_nil

      expect(json_body.dig(:data, :teamActivate, :errors)).to include(/User does not belong to this team/)
    end
  end
end
