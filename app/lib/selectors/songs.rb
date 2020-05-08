# frozen_string_literal: true

module Selectors
  class Songs
    attr_reader :arel, :lookahead
    def initialize(lookahead:)
      @arel = Song.arel_table
      @songs = record_context(lookahead)
    end

    def songs
      @songs.order(created_at: :asc)
    end

    def for_user(user)
      @songs = @songs.joins(:user_library_records).where(user_library_records: { user: user })

      self
    end

    def without_pending_records
      library_arel = UserLibraryRecord.arel_table

      @songs = @songs.joins(:user_library_records)
                     .where(library_arel[:source].not_eq("pending_recommendation")
                       .or(library_arel[:source].eq(nil)))

      self
    end

    def with_query(query)
      return self if query.blank?

      @songs = @songs.where(Song.arel_table[:name].matches("%#{query}%"))
      self
    end

    def with_user_tags(_user, tag_ids)
      return self if tag_ids.blank?

      @songs = @songs.joins(:tag_songs).where(tags_songs: { tag_id: tag_ids }).distinct if tag_ids.present?
      self
    end

    private

    def record_context(lookahead)
      includes = []
      includes << :tags if lookahead.selects?(:tags)
      includes << :tag_songs if lookahead.selects?(:tags)
      return Song if includes.blank?

      Song.includes(includes)
    end
  end
end
