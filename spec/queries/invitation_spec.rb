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
        }
      }
    )
  end

  describe "query" do
    it "returns an invitation if queried" do
      variables = {
        email: "jimbo@derp.com",
        token: SecureRandom.uuid
      }
      post("/api/v1/graphql", params: { query: query, variables: variables })

      expect(response).to be_successful
    end
  end
end
