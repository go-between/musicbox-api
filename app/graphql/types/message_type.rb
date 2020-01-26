# frozen_string_literal: true

module Types
  class MessageType < Types::BaseObject
    graphql_name "Message"

    field :id, ID, null: false
    field :message, String, null: false
    field :created_at, Types::DateTimeType, null: false

    field :room_playlist_record, Types::RoomPlaylistRecordType, null: true
    field :room, Types::RoomType, null: false
    field :user, Types::UserType, null: false
  end
end
