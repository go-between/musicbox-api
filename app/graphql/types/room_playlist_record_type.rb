# frozen_string_literal: true

module Types
  class RoomPlaylistRecordType < Types::BaseObject
    graphql_name 'RoomPlaylistRecord'

    field :id, ID, null: false
    field :order, Int, null: false
    field :played_at, Types::DateTimeType, null: true
    field :room, Types::RoomType, null: false
    field :song, Types::SongType, null: false
    field :user, Types::UserType, null: false
  end
end
