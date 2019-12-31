# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    graphql_name 'Query'

    field :room, Types::RoomType, null: true do
      argument :id, ID, required: true
    end

    def room(id:)
      rooms = Room.where(id: id)
      rooms = rooms.where(team: context[:current_user].teams) if context[:current_user].present?
      rooms.first
    end

    field :rooms, [Types::RoomType], null: true do
    end

    def rooms
      Room.where(team: context[:current_user].active_team)
    end

    field :room_playlist, [Types::RoomPlaylistRecordType], null: true do
      argument :room_id, ID, required: true
    end

    def room_playlist(room_id:)
      RoomPlaylist.new(room_id).generate_playlist
    end

    field :song, Types::SongType, null: true do
      argument :id, ID, required: true
    end

    def song(id:)
      Song.find(id)
    end

    field :songs, [Types::SongType], null: true do
    end

    def songs
      context[:current_user].songs
    end
  end
end
