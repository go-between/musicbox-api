# frozen_string_literal: true

module Selectors
  class Songs
    attr_reader :arel, :lookahead, :user
    def initialize(lookahead:, user:)
      @user = user

      @arel = Song.arel_table
      @songs = record_context(lookahead)
    end

    def songs(order:)
      return @songs.order(created_at: :asc) if order.blank?
      return [] unless Song.column_names.include?(order[:field])

      @songs.order(order[:field] => order[:direction])
    end

    def for_user
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

    def with_tags(tag_ids)
      return self if tag_ids.blank?

      @songs = @songs.joins(:tag_songs).where(tags_songs: { tag_id: tag_ids }).distinct
      self
    end

    private

    def record_context(lookahead)
      ctx = Song
      if lookahead.selects?(:tags)
        tags_arel = Tag.arel_table
        ctx = ctx.includes(%i[tags tag_songs])
                 .where(
                   tags_arel[:user_id].eq(user.id).or(tags_arel[:user_id].eq(nil))
                 ).references(:tags)
      end

      ctx
    end
  end
end
