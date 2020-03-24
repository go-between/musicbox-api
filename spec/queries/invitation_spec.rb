# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitation Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query InvitationQuery($email: String!, $token: ID!) {
        invitation(email: $email, token: $token) {
          email
          name
          invitationState
          team {
            name
          }
          invitingUser {
            name
          }
          invitedUser {
            name
          }
        }
      }
    )
  end

  describe "query" do
    it "returns an invitation if queried" do
      inviting_user = create(:user, name: "friend of jimbo")
      team = create(:team)
      create(:user, email: "jimbo@derp.com", name: "jimbo derpio")
      invitation = Invitation.create!(
        name: "jimbo derp",
        email: "jimbo@derp.com",
        inviting_user: inviting_user,
        team: team,
        token: Invitation.token,
        invitation_state: "pending"
      )

      variables = {
        email: "jimbo@derp.com",
        token: invitation.token
      }
      post("/api/v1/graphql", params: { query: query, variables: variables })

      expect(json_body.dig(:data, :invitation, :email)).to eq("jimbo@derp.com")
      expect(json_body.dig(:data, :invitation, :name)).to eq("jimbo derp")
      expect(json_body.dig(:data, :invitation, :invitingUser, :name)).to eq("friend of jimbo")
      expect(json_body.dig(:data, :invitation, :invitedUser, :name)).to eq("jimbo derpio")
    end
  end
end
