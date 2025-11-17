# frozen_string_literal: true

class Song < ApplicationRecord
  validates :youtube_id, presence: true
  has_many :library_records, inverse_of: :song
  has_many :users, through: :library_records

  # Full-text search across weighted fields (name, channel, tags, description)
  scope :fulltext_search, ->(query) {
    return none if query.blank?

    where("text_search @@ plainto_tsquery(?)", query)
      .reorder(Arel.sql(sanitize_sql_array([ "ts_rank(text_search, plainto_tsquery(?)) DESC", query ])))
  }

  # Fuzzy trigram search for substring matching across name, channel, and tags
  scope :fuzzy_search, ->(query) {
    return none if query.blank?

    # Build expression for combined searchable content (qualify columns with table name to avoid ambiguity)
    searchable_expr = "COALESCE(songs.name, '') || ' ' || COALESCE(songs.channel_title, '') || ' ' || COALESCE(immutable_array_to_string(songs.youtube_tags, ' '), '')"

    where(sanitize_sql_array([ "(?) <% (#{searchable_expr})", query ]))
      .reorder(Arel.sql(sanitize_sql_array([ "(?) <<-> (#{searchable_expr})", query ])))
  }

  # Combined search: 3-tier approach for maximum recall
  # Tier 1: Full-text search (best for word/phrase matching)
  # Tier 2: Trigram fuzzy (handles typos, similar words)
  # Tier 3: ILIKE substring (guaranteed contains matching)
  scope :search, ->(query) {
    return none if query.blank?

    # Build the searchable expression for fuzzy and ILIKE searches
    searchable_expr = "COALESCE(songs.name, '') || ' ' || COALESCE(songs.channel_title, '') || ' ' || COALESCE(immutable_array_to_string(songs.youtube_tags, ' '), '')"

    # Build conditions for all three search types
    fts_condition = sanitize_sql_array([ "text_search @@ plainto_tsquery(?)", query ])
    fuzzy_condition = sanitize_sql_array([ "(?) <% (#{searchable_expr})", query ])
    ilike_condition = sanitize_sql_array([ "#{searchable_expr} ILIKE ?", "%#{query}%" ])

    # Combine all three searches with tier-based sorting
    where("#{fts_condition} OR #{fuzzy_condition} OR #{ilike_condition}")
      .order(Arel.sql(sanitize_sql_array([
        "CASE " +
        "WHEN #{fts_condition} THEN 1 " +
        "WHEN #{fuzzy_condition} THEN 2 " +
        "ELSE 3 END ASC, " +
        "CASE " +
        "WHEN #{fts_condition} THEN ts_rank(text_search, plainto_tsquery(?)) " +
        "WHEN #{fuzzy_condition} THEN word_similarity(?, #{searchable_expr}) " +
        "ELSE 0 END DESC",
        query, query
      ])))
  }
end
