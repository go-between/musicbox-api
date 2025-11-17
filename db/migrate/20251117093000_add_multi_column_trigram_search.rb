class AddMultiColumnTrigramSearch < ActiveRecord::Migration[6.0]
  def up
    # Create GiST trigram index on combined text fields for fuzzy substring matching
    execute <<-SQL
      CREATE INDEX index_songs_on_searchable_content_trgm
      ON songs USING gist((
        COALESCE(name, '') || ' ' ||
        COALESCE(channel_title, '') || ' ' ||
        COALESCE(immutable_array_to_string(youtube_tags, ' '), '')
      ) gist_trgm_ops);
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_songs_on_searchable_content_trgm;"
  end
end
