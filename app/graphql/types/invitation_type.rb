# frozen_string_literal: true

module Types
  class InvitationType < Types::BaseObject
    graphql_name "Invitation"

    field :email, String, null: false
    field :name, String, null: false
    field :invitation_state, String, null: false
    field :inviting_user, Types::UserType, null: false
    field :invited_user, Types::UserType, null: true
    field :team, Types::TeamType, null: false
  end
end
