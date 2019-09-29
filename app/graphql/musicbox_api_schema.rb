# frozen_string_literal: true

class MusicboxApiSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)
end
