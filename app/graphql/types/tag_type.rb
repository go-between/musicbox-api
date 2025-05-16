# frozen_string_literal: true

module Types
  class TagType < Types::BaseObject
    graphql_name "Tag"

    field :id, ID, null: false
    field :name, String, null: false
    field :user, Types::UserType, null: false
    field :library_records, [ Types::LibraryRecordType ], null: false
  end
end
