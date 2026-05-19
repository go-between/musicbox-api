# Step 16 — features/music-library

- **id:** 16
- **kind:** produce
- **target:** `autopilot-support/index/features/music-library/{map,patterns,boundaries}.md`

## Outputs
- `autopilot-support/index/features/music-library/map.md`
- `autopilot-support/index/features/music-library/patterns.md`
- `autopilot-support/index/features/music-library/boundaries.md`

## Scope (from feature_classification.csv, Feature = "User Music Library")
- `app/graphql/mutations/library_record_delete.rb`
- `app/graphql/types/library_record_type.rb`
- `app/lib/selectors/library_records.rb`
- `app/models/library_record.rb`
- `db/migrate/20190319133140_create_join_table_user_song.rb`
- `db/migrate/20190702133426_add_id_to_songs_users.rb`
- `db/migrate/20190927232709_rename_songs_users.rb`
- `db/migrate/20190927234716_rename_user_library_songs.rb`
- `db/migrate/20200424153153_add_source_data_to_user_library_records.rb`
- `db/migrate/20200513033849_rename_user_library_records.rb`
- `db/migrate/20200515034314_add_library_record_indexes.rb`
- `spec/factories/library_record.rb`
- `spec/models/library_record_spec.rb`
- `spec/mutations/library_record_delete_spec.rb`
- `spec/queries/library_records_spec.rb`

## Verify
- All three files non-empty: PASS
- Every CSV basename present in `map.md`: PASS
- No line-number references (`:[0-9]+`) in feature dir: PASS

## Notes
- `User#library_records` default filter (`source <> "pending_recommendation" OR source IS NULL`) is the single most important non-obvious behavior; surfaced in both `patterns.md` and `boundaries.md`.
- Selector's `with_query` requires `Song.search(query).reorder("")` to coexist with `DISTINCT`; called out as a do-not-build footgun.
- Migration trail (`songs_users` → `user_library_songs` → `user_library_records` → `library_records`) recorded in `map.md` and summarized in `patterns.md` so future readers grepping the older names land in the right place.
- Creation paths intentionally live elsewhere (history, recommendations, songs/search); boundaries call out the no-`LibraryRecordCreate` rule.
