# frozen_string_literal: true

module Mutations
  class TeamCreate < Mutations::BaseMutation
    class TeamOwnerInputObject < Types::BaseInputObject
      argument :email, String, required: true
      argument :name, String, required: true
      argument :password, String, required: true
    end

    argument :team_owner, TeamOwnerInputObject, required: true
    argument :team_name, String, required: true
    field :access_token, ID, null: true
    field :errors, [String], null: true

    def resolve(team_owner:, team_name:)
      # Note:  Presumably we also will accept a billing object
      #        and ensure that it contains a valid payment mechanism
      #        before allowing the rest of this to happen.
      team_owner = ensure_user!(team_owner)
      return { errors: ["Unable to authenticate user"] } if team_owner.blank?

      team = Team.create!(name: team_name, owner: team_owner)
      team_owner.teams << team

      {
        access_token: access_token_for(team_owner.id),
        errors: []
      }
    end

    private

    def access_token_for(user_id)
      Doorkeeper::AccessToken.create!(
        resource_owner_id: user_id,
        expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
        scopes: ""
      ).token
    end

    def ensure_user!(email:, password:, name:, **_kwargs)
      user = User.find_for_database_authentication(email: email)
      return create_user!(email: email, password: password, name: name) if user.blank?
      return user if user.valid_for_authentication? { user.valid_password?(password) }
    end

    def create_user!(email:, password:, name:)
      user = User.new(email: email, name: name, password: password)
      return unless user.valid?

      user.save!
      user
    end
  end
end
