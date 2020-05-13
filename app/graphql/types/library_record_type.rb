# frozen_string_literal: true

module Types
  class LibraryRecordType < Types::BaseObject
    graphql_name "LibraryRecord"

    field :id, ID, null: false
    field :source, String, null: true
    field :created_at, Types::DateTimeType, null: false

    field :from_user, Types::UserType, null: true
    field :song, Types::SongType, null: true
    field :user, Types::UserType, null: true
  end
end
