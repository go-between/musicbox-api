# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    private

    def current_user
      context[:current_user]
    end
  end
end
