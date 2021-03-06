# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitation Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation InvitationCreate($email: String!, $name: String!) {
        invitationCreate(input:{
          email: $email,
          name: $name
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe "success" do
    it "creates an invitation" do
      team = create(:team)
      current_user.update!(active_team: team)

      # Ensure that we delegate to SecureRandom for token generation
      expect(Invitation).to receive(:token).and_return("fbb586a9-b798-4a31-a634-66d28a661375")
      graphql_request(
        query: query,
        user: current_user,
        variables: { email: "an-invited-user@atdot.com", name: "the user" }
      )

      invitation = Invitation.find_by(email: "an-invited-user@atdot.com")
      expect(invitation).to be_present
      expect(invitation.inviting_user).to eq(current_user)
      expect(invitation.team).to eq(current_user.active_team)
      expect(invitation.token).to eq("fbb586a9-b798-4a31-a634-66d28a661375")
      expect(invitation).to be_pending
      expect(EmailInvitationWorker).to have_enqueued_sidekiq_job(invitation.id)
    end

    it "allows a new invitation for a different team" do
      team = create(:team)
      current_user.update!(active_team: team)
      other_team = create(:team)
      Invitation.create!(
        email: "an-invited-user@atdot.com",
        inviting_user: current_user,
        token: Invitation.token,
        team: other_team
      )

      # Ensure that we delegate to SecureRandom for token generation
      expect(Invitation).to receive(:token).and_return("c20f47c1-f267-44da-8fc3-462c20bdadb5")
      graphql_request(
        query: query,
        user: current_user,
        variables: { email: "an-invited-user@atdot.com", name: "the user" }
      )

      other_invitation = Invitation.find_by(token: "c20f47c1-f267-44da-8fc3-462c20bdadb5")
      expect(other_invitation.email).to eq("an-invited-user@atdot.com")
      expect(other_invitation.team).to eq(team)
      expect(other_invitation.inviting_user).to eq(current_user)
      expect(other_invitation).to be_pending
    end

    it "does not create a new invitation when one exists for a team" do
      team = create(:team)
      current_user.update!(active_team: team)
      token = Invitation.token
      invitation = Invitation.create!(
        email: "an-invited-user@atdot.com",
        inviting_user: current_user,
        token: token,
        team: team
      )

      # Another user on the same team also invites this user
      other_user = create(:user, active_team: team)
      expect do
        graphql_request(
          query: query,
          user: other_user,
          variables: { email: "an-invited-user@atdot.com", name: "the user" }
        )

        expect(json_body.dig(:data, :invitationCreate, :errors)).to be_empty
      end.not_to change(Invitation, :count)

      invitation.reload
      expect(invitation.token).to eq(token)
      expect(invitation.email).to eq("an-invited-user@atdot.com")
      expect(invitation.team).to eq(team)
      expect(invitation.inviting_user).to eq(current_user)
      expect(invitation).to be_pending
    end

    it "does not reset state when previously accepted" do
      team = create(:team)
      current_user.update!(active_team: team)
      invitation = Invitation.create!(
        email: "an-invited-user@atdot.com",
        team: team,
        token: "fbb586a9-b798-4a31-a634-66d28a661375",
        inviting_user: current_user,
        invitation_state: :accepted
      )

      expect(Invitation).not_to receive(:token)
      graphql_request(
        query: query,
        user: current_user,
        variables: { email: "an-invited-user@atdot.com", name: "the user" }
      )

      invitation.reload
      expect(invitation).to be_accepted
    end

    it "is unauthorized if user is not logged in" do
      post(
        "/api/v1/graphql",
        params: {
          query: query,
          variables: {
            email: "an-invited-user@atdot.com",
            name: "the user"
          }
        }
      )

      expect(response).to be_unauthorized
    end
  end

  describe "error" do
    it "does not allow an invitation to be created without a team" do
      current_user.update!(active_team: nil)
      expect do
        graphql_request(
          query: query,
          user: current_user,
          variables: { email: "an-invited-user@atdot.com", name: "the user" }
        )

        errors = json_body.dig(:data, :invitationCreate, :errors)
        expect(errors).to include(/Must be on an active team/)
      end.not_to change(Invitation, :count)
    end
  end
end
