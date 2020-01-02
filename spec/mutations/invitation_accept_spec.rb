# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Invitation Create', type: :request do
  include AuthHelper
  include JsonHelper

  def query(email:, password:, name:, token:)
    %(
      mutation {
        invitationAccept(input:{
          invitation: {
            email: "#{email}",
            password: "#{password}",
            token: "#{token}",
            name: "#{name}"
          }
        }) {
          accessToken
          errors
        }
      }
    )
  end

  let(:team) { create(:team) }
  let(:inviting_user) { create(:user) }
  let!(:invitation) do
    Invitation.create!(
      email: 'an-invited-user@atdot.com',
      team: team,
      inviting_user: inviting_user,
      token: 'fbb586a9-b798-4a31-a634-66d28a661375',
      invitation_state: :pending
    )
  end

  describe 'success' do
    it 'accepts an invitation' do
      query = query(
        email: 'an-invited-user@atdot.com',
        password: 'foobar',
        token: 'fbb586a9-b798-4a31-a634-66d28a661375',
        name: 'Blorg Blargaborg'
      )

      graphql_request(
        query: query,
        user: inviting_user
      )

      invitation.reload
      expect(invitation).to be_accepted

      user = User.find_by(email: 'an-invited-user@atdot.com')
      expect(user.valid_password?('foobar')).to eq(true)
      expect(user.teams).to include(team)

      token = Doorkeeper::AccessToken.find_by(token: json_body.dig(:data, :invitationAccept, :accessToken))
      expect(token.resource_owner_id).to eq(user.id)
    end

    it 'adds an existing user to the invited team' do
      other_team = create(:team)
      user = User.create!(email: 'an-invited-user@atdot.com', password: 'foobar', teams: [other_team])

      query = query(
        email: 'an-invited-user@atdot.com',
        password: 'foobar',
        token: 'fbb586a9-b798-4a31-a634-66d28a661375',
        name: 'Blorg Blargaborg'
      )

      expect do
        graphql_request(
          query: query,
          user: inviting_user
        )
      end.not_to change(User, :count)

      user.reload
      expect(user.teams.map(&:id)).to match_array([team.id, other_team.id])
    end

    it 'does not duplicate teams for a user' do
      user = User.create!(email: 'an-invited-user@atdot.com', password: 'foobar', teams: [team])

      query = query(
        email: 'an-invited-user@atdot.com',
        password: 'foobar',
        token: 'fbb586a9-b798-4a31-a634-66d28a661375',
        name: 'Blorg Blargaborg'
      )

      expect do
        graphql_request(
          query: query,
          user: inviting_user
        )
      end.not_to change(User, :count)

      user.reload
      expect(user.teams.map(&:id)).to match_array([team.id])
    end
  end

  describe 'error' do
    it 'does not accept the invitation with an invalid email' do
      query = query(
        email: 'an-invited-user@atdotdotdotdotdot.com',
        password: 'foobar',
        token: 'fbb586a9-b798-4a31-a634-66d28a661375',
        name: 'Blorg Blargaborg'
      )

      expect do
        graphql_request(
          query: query,
          user: inviting_user
        )
      end.not_to change(User, :count)

      invitation.reload
      expect(invitation).to be_pending

      expect(json_body.dig(:data, :invitationAccept, :accessToken)).to be_nil
      expect(json_body.dig(:data, :invitationAccept, :errors)).to include(/Invalid invitation/)
    end

    it 'does not accept the invitation with an invalid token' do
      query = query(
        email: 'an-invited-user@atdot.com',
        password: 'foobar',
        token: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        name: 'Blorg Blargaborg'
      )

      expect do
        graphql_request(
          query: query,
          user: inviting_user
        )
      end.not_to change(User, :count)

      invitation.reload
      expect(invitation).to be_pending

      expect(json_body.dig(:data, :invitationAccept, :accessToken)).to be_nil
      expect(json_body.dig(:data, :invitationAccept, :errors)).to include(/Invalid invitation/)
    end

    it 'does not accept an invitation when user exists and does not auth' do
      user = User.create!(email: 'an-invited-user@atdot.com', password: 'foobar', teams: [])

      query = query(
        email: 'an-invited-user@atdot.com',
        password: 'wrongwrongwrong',
        token: 'fbb586a9-b798-4a31-a634-66d28a661375',
        name: 'Blorg Blargaborg'
      )

      expect do
        graphql_request(
          query: query,
          user: inviting_user
        )
      end.not_to change(User, :count)

      invitation.reload
      expect(invitation).to be_pending

      user.reload
      expect(user.teams).to be_empty

      expect(json_body.dig(:data, :invitationAccept, :accessToken)).to be_nil
      expect(json_body.dig(:data, :invitationAccept, :errors)).to include(/Unable to authenticate user/)
    end

    it 'does not allow a user to be created with an insecure password' do
      query = query(
        email: 'an-invited-user@atdot.com',
        password: 'bird',
        token: 'fbb586a9-b798-4a31-a634-66d28a661375',
        name: 'Blorg Blargaborg'
      )

      expect do
        graphql_request(
          query: query,
          user: inviting_user
        )
      end.not_to change(User, :count)

      invitation.reload
      expect(invitation).to be_pending

      expect(json_body.dig(:data, :invitationAccept, :accessToken)).to be_nil
      expect(json_body.dig(:data, :invitationAccept, :errors)).to include(/Unable to authenticate user/)
    end
  end
end
