# frozen_string_literal: true

module Types
  class RoomType < Types::BaseObject
    graphql_name 'Room'

    field :current_record, Types::RoomPlaylistRecordType, null: true
    field :current_song, Types::SongType, null: true
    field :name, String, null: false
    field :id, ID, null: false
    field :users, [Types::UserType], null: false
  end
end
