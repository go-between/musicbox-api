# frozen_string_literal: true

module Types
  class RecordListenType < Types::BaseObject
    graphql_name "RecordListen"

    field :id, ID, null: false
    field :approval, Int, null: false

    field :room_playlist_record, Types::RoomPlaylistRecordType, null: false
    field :song, Types::SongType, null: false
    field :user, Types::UserType, null: false
  end
end
