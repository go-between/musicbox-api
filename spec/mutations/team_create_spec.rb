# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitation Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation TeamCreate($teamOwner: TeamOwnerInputObject!, $teamName: String!) {
        teamCreate(input:{
          teamOwner: $teamOwner,
          teamName: $teamName
        }) {
          accessToken
          errors
        }
      }
    )
  end

  describe "success" do
    it "creates a team for a new user" do
      variables = {
        teamOwner: {
          email: "TEAM-owner@ATDOT.com",
          password: "foobar",
          name: "Trickster"
        },
        teamName: "FrogTown"
      }

      expect do
        post(
          "/api/v1/graphql",
          params: { query: query, variables: variables }
        )
      end.to change(User, :count).by(1).and(change(Team, :count).by(1))

      team = Team.find_by(name: "FrogTown")
      # Ensure email is downcased
      user = User.find_by(email: "team-owner@atdot.com")
      expect(team.owner).to eq(user)
      expect(user.valid_password?("foobar")).to be(true)
      expect(user.teams).to include(team)

      token = Doorkeeper::AccessToken.find_by(token: json_body.dig(:data, :teamCreate, :accessToken))
      expect(token.resource_owner_id).to eq(user.id)
    end

    it "creates a new team for an existing user" do
      User.create!(email: "team-owner@atdot.com", password: "foobar", teams: [])
      variables = {
        teamOwner: {
          email: "team-OWNER@atdot.COM",
          password: "foobar",
          name: "Trickster"
        },
        teamName: "FrogTown"
      }

      expect(Team.exists?(name: "FrogTown ")).to be(false)
      expect do
        post(
          "/api/v1/graphql",
          params: { query: query, variables: variables }
        )
      end.not_to change(User, :count)

      team = Team.find_by(name: "FrogTown")
      user = User.find_by(email: "team-owner@atdot.com")
      expect(team.owner).to eq(user)
      expect(user.valid_password?("foobar")).to be(true)
      expect(user.teams).to include(team)

      token = Doorkeeper::AccessToken.find_by(token: json_body.dig(:data, :teamCreate, :accessToken))
      expect(token.resource_owner_id).to eq(user.id)
    end
  end

  describe "error" do
    it "does not create a team when user exists and does not auth" do
      user = User.create!(email: "team-owner@atdot.com", password: "foobar", teams: [])

      variables = {
        teamOwner: {
          email: "team-owner@atdot.com",
          password: "flimflam",
          name: "Trickster"
        },
        teamName: "FrogTown"
      }

      expect do
        post(
          "/api/v1/graphql",
          params: { query: query, variables: variables }
        )
      end.not_to change(User, :count)

      user.reload
      expect(user.teams).to be_empty

      expect(json_body.dig(:data, :teamCreate, :accessToken)).to be_nil
      expect(json_body.dig(:data, :teamCreate, :errors)).to include(/Unable to authenticate user/)
    end

    it "does not allow a user to be created with an insecure password" do
      variables = {
        teamOwner: {
          email: "team-owner@atdot.com",
          password: "easy",
          name: "Trickster"
        },
        teamName: "FrogTown"
      }

      expect do
        post(
          "/api/v1/graphql",
          params: { query: query, variables: variables }
        )
      end.not_to change(User, :count)

      expect(json_body.dig(:data, :teamCreate, :accessToken)).to be_nil
      expect(json_body.dig(:data, :teamCreate, :errors)).to include(/Unable to authenticate user/)
    end
  end
end
