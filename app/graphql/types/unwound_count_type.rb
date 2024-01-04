# frozen_string_literal: true

module Types
  class UnwoundCountType < Types::BaseObject
    graphql_name "UnwoundCount"

    field :label, String, null: false
    field :count, Int, null: false
    field :length, Int, null: false
  end
end
