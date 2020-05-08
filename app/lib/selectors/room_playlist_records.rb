# frozen_string_literal: true

module Selectors
  class RoomPlaylistRecords
    attr_reader :arel, :from, :lookahead
    def initialize(lookahead:)
      @lookahead = lookahead

      @arel = RoomPlaylistRecord.arel_table
    end

    def select(room_id:, historical:, from:)
      if historical
        relation = record_context.where(room_id: room_id).played.order(played_at: :desc)
        relation = relation.where(RoomPlaylistRecord.arel_table[:played_at].gteq(from)) if from.present?
        relation
      else
        room = Room.find(room_id)
        RoomPlaylistGenerator.new(room, record_context).playlist
      end
    end

    private

    def record_context
      includes = []
      includes << :record_listens if lookahead.selects?(:record_listens)
      includes << :song if lookahead.selects?(:song)
      includes << :user if lookahead.selects?(:user)

      return RoomPlaylistRecord if includes.blank?

      RoomPlaylistRecord.includes(includes)
    end
  end
end
