# User Music Library — Map

## Model
- `app/models/library_record.rb` — The user↔song join row with `source` enum (`saved_from_history`, `pending_recommendation`, `accepted_recommendation`), optional `from_user` (recommender), and `has_many :tags` through `tag_library_records`.

## GraphQL
- `app/graphql/types/library_record_type.rb` — Read shape exposed to clients: `source`, `from_user`, `song`, `user`, `tags`. No mutation fields (creation happens via sibling features).
- `app/graphql/mutations/library_record_delete.rb` — Only mutation owned by this feature. Scopes lookup to `current_user`, returns `"Can't find song to delete"` on miss, hard-`destroy!`s on success.

## Selector
- `app/lib/selectors/library_records.rb` — Chainable query builder. `.for_user`, `.without_pending_records`, `.with_query`, `.with_tags` compose with optional `order:`; lookahead drives `includes` to avoid N+1.

## Migrations (table-rename trail)
- `db/migrate/20190319133140_create_join_table_user_song.rb` — Initial `songs_users` join table, `(user_id, song_id)` only.
- `db/migrate/20190702133426_add_id_to_songs_users.rb` — Drops & recreates `songs_users` with UUID `id` + timestamps; upgrades it from join table to a real model.
- `db/migrate/20190927232709_rename_songs_users.rb` — `songs_users` → `user_library_songs`.
- `db/migrate/20190927234716_rename_user_library_songs.rb` — `user_library_songs` → `user_library_records`.
- `db/migrate/20200424153153_add_source_data_to_user_library_records.rb` — Adds `from_user_id` and `source` columns; introduces recommendation provenance.
- `db/migrate/20200513033849_rename_user_library_records.rb` — `user_library_records` → `library_records` (current name).
- `db/migrate/20200515034314_add_library_record_indexes.rb` — Indexes `created_at` and `source` (selector's default order + pending filter).

## Specs
- `spec/factories/library_record.rb` — Factory; `source` defaults to `nil` (a plain saved record).
- `spec/models/library_record_spec.rb` — Smoke coverage of `song`/`user`/`tags` relationships.
- `spec/mutations/library_record_delete_spec.rb` — Confirms cross-user delete is blocked via the `current_user` scope.
- `spec/queries/library_records_spec.rb` — Exercises the selector end-to-end: pending exclusion, song-name search, tag filter, combined query+tag, default and song-name ordering, SQL-injection guard on `order.field`.
