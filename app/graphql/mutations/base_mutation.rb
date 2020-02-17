# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    private

    def current_user
      context[:current_user]
    end

    def access_token_for(user_id)
      Doorkeeper::AccessToken.create!(
        resource_owner_id: user_id,
        expires_in: nil,
        scopes: ""
      ).token
    end
  end
end
