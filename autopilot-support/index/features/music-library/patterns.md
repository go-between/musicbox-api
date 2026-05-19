# User Music Library — Patterns

## LibraryRecord is the user↔song join, not a wrapper
- `LibraryRecord` exists only to materialize the many-to-many between `User` and `Song` with row-level metadata (`source`, `from_user`, `tags`). Song attributes are never duplicated here — always traverse `library_record.song`.
- The table has been renamed three times (see the migration trail in `map.md`): `songs_users` → `user_library_songs` → `user_library_records` → `library_records`. Old branches, dumps, or external scripts may reference the older names; only `library_records` is current.

## `source` enum encodes recommendation provenance
- `source` is `nil` for organically saved records, `saved_from_history` when promoted from `RecordListen`, and `pending_recommendation` / `accepted_recommendation` when the row originated from the recommendation feature. `from_user_id` carries the recommender.
- Treat the recommendation lifecycle as owned by **recommendations**; this feature only stores the resulting state and filters on it.

## `pending_recommendation` is filtered out at the association
- `User#library_records` in `app/models/user.rb` defines the association with a default `where` that excludes `source = "pending_recommendation"`. It uses an explicit `or(source IS NULL)` because Postgres `<>` drops NULL rows — drop that clause and unsourced records silently disappear.
- Consequence: `user.library_records`, `user.songs`, and anything that flows through the association already hides pending recs. Code that needs to see them must query `LibraryRecord` directly (e.g., the recommendation acceptance flow).

## Selector composition, not scopes
- `Selectors::LibraryRecords` is the canonical query path. It is built around mutable `@library_records` state where each chain method returns `self`. `library_records(order:)` is the terminal call.
- `without_pending_records` exists on the selector even though `User#library_records` already excludes them — it's there for callers that start from `LibraryRecord` directly and need the same guard.
- `with_query` joins `songs` and merges `Song.search(query)` with `reorder("")` stripped; ordering is then re-applied at the `library_records` level via `apply_song_search_order` to coexist with `DISTINCT`. Do not call `Song.search` here without that reorder strip.
- `order_by_field` and `order_by_relation` both validate against `column_names` and an allow-list of associations — this is the SQL-injection guard exercised by the `"DROP TABLE"` spec. New sortable fields must remain real columns; arbitrary expressions are rejected by design.
- `record_context(lookahead)` uses GraphQL lookahead to add `includes(:from_user | :tags | :song | :user)` only when the client selected them. Adding a new association on `LibraryRecordType` means adding a matching `*_context!` branch.

## Deletion is destructive
- `LibraryRecordDelete` calls `record.destroy!` — there is no soft-delete column, no archival, no tombstone. Tags attached via `tag_library_records` ride along through `dependent` semantics on the join (see tagging feature).
- The lookup `LibraryRecord.find_by(id:, user: context[:current_user])` is the only authorization check; the error string `"Can't find song to delete"` is asserted by spec and is the contract.

## What this feature does not own
- Creation of records is split across siblings: history promotion lives in **listening-history**, recommendation acceptance in **recommendations**, manual saves in **songs**/**search** flows. There is intentionally no `LibraryRecordCreate` mutation.
- The `libraryRecords` query field is wired in the GraphQL query type (see `structures/resources.md`); the selector is what this feature owns, not the resolver registration.
