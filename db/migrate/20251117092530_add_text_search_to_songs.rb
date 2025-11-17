class AddTextSearchToSongs < ActiveRecord::Migration[6.0]
  def up
    # Create an immutable wrapper for array_to_string
    execute <<-SQL
      CREATE OR REPLACE FUNCTION immutable_array_to_string(text[], text)
      RETURNS text AS $$
        SELECT array_to_string($1, $2);
      $$ LANGUAGE SQL IMMUTABLE;
    SQL

    # Add the text_search generated column with weighted fields
    execute <<-SQL
      ALTER TABLE songs ADD COLUMN text_search tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english'::regconfig, COALESCE(name, '')), 'A') ||
        setweight(to_tsvector('english'::regconfig, COALESCE(channel_title, '')), 'A') ||
        setweight(to_tsvector('english'::regconfig, COALESCE(immutable_array_to_string(youtube_tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english'::regconfig, COALESCE(description, '')), 'C')
      ) STORED;
    SQL

    # Add GIN index for fast full text search
    add_index :songs, :text_search, using: :gin
  end

  def down
    remove_index :songs, :text_search
    remove_column :songs, :text_search
    execute "DROP FUNCTION IF EXISTS immutable_array_to_string(text[], text);"
  end
end
