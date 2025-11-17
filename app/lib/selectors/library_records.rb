# frozen_string_literal: true

module Selectors
  class LibraryRecords
    attr_reader :arel, :lookahead, :user

    def initialize(lookahead:, user:)
      @user = user
      @search_query = nil

      @arel = LibraryRecord.arel_table
      @library_records = record_context(lookahead)
    end

    def library_records(order: nil)
      # If no explicit order but we have a search query, order by song search relevance
      if order.blank? && @search_query.present?
        return apply_song_search_order(@search_query)
      end

      return @library_records.order(created_at: :asc) if order.blank?
      return [] unless %w[asc desc].include?(order[:direction])

      order_fields = order[:field].split(".")
      case order_fields.size
      when 1
        order_by_field(order_fields.first, order[:direction])
      when 2
        order_by_relation(order_fields.first, order_fields.second, order[:direction])
      else
        []
      end
    end

    def for_user
      @library_records = @library_records.where(user: user)

      self
    end

    def without_pending_records
      @library_records = @library_records.where(
        arel[:source].not_eq("pending_recommendation").or(arel[:source].eq(nil))
      )

      self
    end

    def with_query(query)
      return self if query.blank?

      @search_query = query
      # Merge Song.search but strip ORDER BY to avoid DISTINCT conflicts
      # We'll apply song ordering later in library_records()
      @library_records = @library_records.joins(:song).merge(Song.search(query).reorder(""))
      self
    end

    def with_tags(tag_ids)
      return self if tag_ids.blank?

      @library_records = @library_records
                         .joins(:tag_library_records)
                         .where(tags_library_records: { tag_id: tag_ids })
                         .distinct
      self
    end

    private

    def apply_song_search_order(query)
      # Apply the same 3-tier ordering logic as Song.search but at library_records level (after DISTINCT)
      # Add ORDER BY expressions to SELECT to support DISTINCT
      searchable_expr = "COALESCE(songs.name, '') || ' ' || COALESCE(songs.channel_title, '') || ' ' || COALESCE(immutable_array_to_string(songs.youtube_tags, ' '), '')"
      fts_condition = Song.sanitize_sql_array([ "songs.text_search @@ plainto_tsquery(?)", query ])
      fuzzy_condition = Song.sanitize_sql_array([ "(?) <% (#{searchable_expr})", query ])

      tier_expr = "CASE " \
                  "WHEN #{fts_condition} THEN 1 " \
                  "WHEN #{fuzzy_condition} THEN 2 " \
                  "ELSE 3 END"
      relevance_expr = Song.sanitize_sql_array([
        "CASE " +
        "WHEN #{fts_condition} THEN ts_rank(songs.text_search, plainto_tsquery(?)) " +
        "WHEN #{fuzzy_condition} THEN word_similarity(?, #{searchable_expr}) " +
        "ELSE 0 END",
        query, query
      ])

      @library_records
        .select("library_records.*")
        .select("#{tier_expr} as search_tier")
        .select("#{relevance_expr} as search_relevance")
        .order("search_tier ASC, search_relevance DESC")
    end

    def order_by_field(field, direction)
      return [] unless LibraryRecord.column_names.include?(field)

      @library_records.order(field => direction)
    end

    def order_by_relation(relation_name, field, direction) # rubocop:disable Metrics/AbcSize
      relation = LibraryRecord.reflect_on_all_associations.find { |rel| rel.name == relation_name.to_sym }
      return [] if relation.blank?
      return [] unless relation.klass.column_names.include?(field)

      relation_arel = relation.klass.arel_table
      @library_records
        .includes(relation.name)
        .order(relation_arel[field].send(direction))
        .references(relation_arel)
    end

    def record_context(lookahead)
      ctx = LibraryRecord
      ctx = from_user_context!(ctx, lookahead)
      ctx = tag_context!(ctx, lookahead)
      ctx = song_context!(ctx, lookahead)
      user_context!(ctx, lookahead)
    end

    def from_user_context!(ctx, lookahead)
      return ctx unless lookahead.selects?(:from_user)

      ctx.includes(:from_user)
    end

    def tag_context!(ctx, lookahead)
      return ctx unless lookahead.selects?(:tags)

      ctx.includes(%i[tags tag_library_records])
    end

    def song_context!(ctx, lookahead)
      return ctx unless lookahead.selects?(:song)

      ctx.includes(:song)
    end

    def user_context!(ctx, lookahead)
      return ctx unless lookahead.selects?(:user)

      ctx.includes(:user)
    end
  end
end
