# frozen_string_literal: true

module Types
  class SongType < Types::BaseObject
    graphql_name "Song"

    field :id, ID, null: false
    field :created_at, Types::DateTimeType, null: false
    field :description, String, null: true
    field :duration_in_seconds, Int, null: true
    field :license, String, null: true
    field :licensed, Boolean, null: false
    field :name, String, null: true
    field :thumbnail_url, String, null: true
    field :youtube_id, ID, null: false
    field :youtube_tags, [ String ], null: false
    field :channel_title, String, null: true
    field :channel_id, String, null: true
    field :published_at, Types::DateTimeType, null: true
    field :category_id, String, null: true

    field :library_records, [ Types::LibraryRecordType ], null: false
  end
end
