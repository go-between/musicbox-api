# frozen_string_literal: true

module Selectors
  class Messages
    attr_reader :arel, :current_user, :to, :from, :lookahead
    def initialize(lookahead:)
      @arel = Message.arel_table
      @messages = record_context(lookahead)
    end

    def messages
      @messages.order(created_at: :asc)
    end

    def for_room_id(room_id:)
      @messages = @messages.where(room_id: room_id)
      self
    end

    def in_date_range(to: nil, from: nil)
      @messages = @messages.where(arel[:created_at].lteq(to)) if to.present?
      @messages = @messages.where(arel[:created_at].gteq(from)) if from.present?
      self
    end

    def when_pinned_to(song_id:)
      @messages = @messages.where(song_id: song_id, pinned: true)
      self
    end

    private

    def record_context(lookahead)
      includes = []
      includes << :room if lookahead.selects?(:room)
      includes << :room_playlist_record if lookahead.selects?(:room_playlist_record)
      includes << :song if lookahead.selects?(:song)
      includes << :user if lookahead.selects?(:user)
      return Message if includes.blank?

      Message.includes(includes)
    end
  end
end
