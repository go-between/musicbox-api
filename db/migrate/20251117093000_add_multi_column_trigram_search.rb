class AddMultiColumnTrigramSearch < ActiveRecord::Migration[6.0]
  def up
    # Create GiST trigram index on combined text fields for fuzzy substring matching
    # siglen=256 provides better precision (5.8x less I/O) with acceptable index size
    execute <<-SQL
      CREATE INDEX index_songs_on_searchable_content_trgm
      ON songs USING gist((
        COALESCE(name, '') || ' ' ||
        COALESCE(channel_title, '') || ' ' ||
        COALESCE(immutable_array_to_string(youtube_tags, ' '), '')
      ) gist_trgm_ops(siglen=256));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_songs_on_searchable_content_trgm;"
  end
end
