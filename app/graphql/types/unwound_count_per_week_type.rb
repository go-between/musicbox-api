# frozen_string_literal: true

module Types
  class UnwoundCountPerWeekType < Types::BaseObject
    graphql_name "UnwoundCountPerWeek"

    field :label, String, null: false
    field :plays, [Types::UnwoundCountType], null: false
  end
end
