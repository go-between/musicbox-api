# Music Tagging — Map

## Models
- `app/models/tag.rb` — User-owned tag. `belongs_to :user`; `has_many :library_records, through: :tag_library_records`. Only validation is `name` presence.
- `app/models/tag_library_record.rb` — Join between `Tag` and `LibraryRecord`. Sets `self.table_name = "tags_library_records"` because the literal table name is plural-plural (the legacy `tags_songs` from initial migrations was renamed in place, not regenerated).

## GraphQL
- `app/graphql/mutations/tag_create.rb` — Mints a new `Tag` scoped to `current_user`. Returns `errors` array on invalid; the only failure mode wired in spec is blank `name`.
- `app/graphql/mutations/tag_toggle.rb` — Bulk add/remove of `tag <-> library_record` joins for a single `tag_id`. Re-scopes the tag through `current_user.tags.find_by(...)` so cross-user toggles surface as `"Tag must be present"`. Uses `TagLibraryRecord.insert_all` for adds and `.delete_all` for removes — no AR callbacks fire.
- `app/graphql/types/tag_type.rb` — Exposes `id`, `name`, `user`, and `library_records`. No song-level field; songs are reached via library records.

## Migrations
- `db/migrate/20200304014052_create_tags_table.rb` — Creates `tags` (uuid PK), `user_id`, `name`. Indexes `user_id` only.
- `db/migrate/20200304014747_create_tags_songs.rb` — Original join table `tags_songs` (tag_id, song_id). Superseded by the rename below; keep in mind when reading old data dumps.
- `db/migrate/20200401223702_add_unique_tags_songs_index.rb` — Adds the uniqueness guarantee on the join, originally on `[tag_id, song_id]`. The successor unique index lives on the renamed table.
- `db/migrate/20200513040509_allow_library_record_to_associate_to_tags.rb` — Pivots the join from songs to library records: backfills `library_record_id` per row by looking up `LibraryRecord` from `(tag.user_id, song_id)`, drops `song_id`, recreates the unique index on `[tag_id, library_record_id]`, and renames `tags_songs` -> `tags_library_records`. Defines a throwaway `TagSong` constant inline. `down` is intentionally irreversible.

## Specs
- `spec/factories/tag.rb` — Trivial factory; default name `"jam city"`, requires associated `user`.
- `spec/models/tag_spec.rb` — Covers `belongs_to :user` and the `library_records` through-association.
- `spec/mutations/tag_create_spec.rb` — Request-level happy path + blank-name error. Asserts `libraryRecords` is empty on a freshly minted tag.
- `spec/mutations/tag_toggle_spec.rb` — Add/remove combo in one call, plus two ownership/missing-tag error cases (uuid not found, tag owned by another user) — both return `"Tag must be present"` and do not mutate the join table.
