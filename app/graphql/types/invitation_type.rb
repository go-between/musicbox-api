# frozen_string_literal: true

module Types
  class InvitationType < Types::BaseObject
    graphql_name "Invitation"

    field :email, String, null: false
    field :name, String, null: false
    field :invitation_state, String, null: false
  end
end
