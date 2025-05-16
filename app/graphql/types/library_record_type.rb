# frozen_string_literal: true

module Types
  class LibraryRecordType < Types::BaseObject
    graphql_name "LibraryRecord"

    field :id, ID, null: false
    field :created_at, Types::DateTimeType, null: false
    field :source, String, null: true

    field :from_user, Types::UserType, null: true
    field :song, Types::SongType, null: true
    field :user, Types::UserType, null: true
    field :tags, [ Types::TagType ], null: true
  end
end
