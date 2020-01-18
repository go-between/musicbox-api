# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query {
        user {
          id
          email
          name
          activeRoom {
            id
          }
          activeTeam {
            id
          }
          teams {
            id
          }
        }
      }
    )
  end

  let(:team) { create(:team) }
  let(:other_team) { create(:team) }
  let(:room) { create(:room, team: team) }

  describe "query" do
    it "returns the details of the current user" do
      user = create(:user, name: "flooper", teams: [team, other_team], active_room: room, active_team: team)

      graphql_request(
        query: query,
        user: user
      )

      user_data = json_body.dig(:data, :user)
      expect(user_data[:id]).to eq(user.id)
      expect(user_data[:email]).to eq(user.email)
      expect(user_data[:name]).to eq(user.name)
      expect(user_data.dig(:activeRoom, :id)).to eq(room.id)
      expect(user_data.dig(:activeTeam, :id)).to eq(team.id)
      expect(user_data[:teams].map { |t| t[:id] }).to match_array([team.id, other_team.id])
    end
  end
end
