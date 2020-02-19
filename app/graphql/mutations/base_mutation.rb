# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    def ready?(**_args)
      raise NotAuthenticatedError, "You have to be logged in." if context[:current_user].blank?

      true
    end

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
