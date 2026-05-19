# User Music Library — Boundaries

## Extension points
- New provenance values plug into the `source` enum on `LibraryRecord`. Add the value, add (or extend) a filter on `Selectors::LibraryRecords`, and decide whether `User#library_records` should hide it by default — that lambda is the single place that controls "what counts as the user's library".
- New filter scopes follow the `with_*` / `without_*` chainable shape on `Selectors::LibraryRecords` (return `self`, mutate `@library_records`). Pair each with a request-level spec in `spec/queries/library_records_spec.rb`.
- New sortable fields must be real columns on `library_records` or on an existing association class — the selector's `order_by_field` / `order_by_relation` deliberately reject anything else. Adding a derived sort means adding an explicit branch, not loosening the guard.
- New eager-loaded associations require both a field on `LibraryRecordType` and a matching `*_context!` branch in `record_context` so lookahead remains the single source of preload truth.
- Additional per-record metadata (e.g., richer recommendation context) belongs as columns on `library_records` alongside `source` / `from_user_id`, not on a sibling table.

## Do-not-build
- Do not bake recommendation acceptance into this feature. The pending → accepted transition belongs to **recommendations**; this feature only stores the resulting `source` value and provides the filter that hides pendings.
- Do not store song metadata (name, channel, duration, YouTube id) on `LibraryRecord`. `Song` owns that; duplicating it here defeats the whole reason this is a join table.
- Do not add soft-delete. `LibraryRecordDelete` is intentionally destructive — adding a `deleted_at` column would silently break the `User#library_records` filter contract and the `pending_recommendation` semantics.
- Do not introduce a `LibraryRecordCreate` mutation. Creation is owned by the originating feature (history promotion, recommendation acceptance, manual save from search). A generic create mutation would let clients bypass those flows' invariants.
- Do not hand-roll the pending filter in callers. Either go through `User#library_records` (already filtered) or chain `Selectors::LibraryRecords#without_pending_records`. Re-implementing the `IS NULL OR <>` clause is a known footgun (see `patterns.md`).
- Do not call `Song.search` from inside the selector without `reorder("")`. The selector relies on stripping Song's ORDER BY to keep `DISTINCT` valid; preserving it produces silent SQL errors.

## Where music-library ends
- **songs** owns `Song` itself, YouTube linkage, and song-level full-text search infrastructure. This feature consumes `Song.search` but does not define it.
- **recommendations** owns the create/accept lifecycle for `pending_recommendation` and `accepted_recommendation` rows. This feature is the storage and read path.
- **tagging** owns `Tag` and `TagLibraryRecord`. The `tags` field on `LibraryRecordType` and the `with_tags` selector method are the integration seam — anything tag-creation related lives there.
- **listening-history** owns `RecordListen` and the promotion path that mints `saved_from_history` records.
- **search** owns the `SearchResult` type and pgtrgm tuning; this feature uses search only as a filter input on `libraryRecords`.
- **user-authentication** owns `current_user` resolution that `LibraryRecordDelete` and the selector rely on.
