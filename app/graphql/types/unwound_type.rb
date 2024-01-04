# frozen_string_literal: true

module Types
  class UnwoundType < Types::BaseObject
    graphql_name "Unwound"

    field :team_plays, [Types::UnwoundCountType], null: false
    field :team_approvals, [Types::UnwoundCountType], null: false
    field :top_plays_over_time, [Types::UnwoundCountPerWeekType], null: false
    field :top_plays, [Types::UnwoundCountType], null: false
    field :top_approvals, [Types::UnwoundCountType], null: false
    field :song_plays_over_time, [Types::UnwoundCountPerWeekType], null: false
    field :song_plays, [Types::UnwoundCountType], null: false
  end
end
