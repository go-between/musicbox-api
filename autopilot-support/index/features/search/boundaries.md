# Search Functionality — Boundaries

What this feature owns, where it ends, and what not to build inside it.

## What this feature owns

- The `search` GraphQL query field's orchestration (the selector, not the field declaration itself, which is wired in `app/graphql/types/query_type.rb`).
- `Types::SearchResultType` — the union over `SongType` and `YoutubeResultType` and the `resolve_type` dispatch.
- `Selectors::SearchResults` — the local-first / YouTube-fallback orchestration and the library-exclusion subquery.
- The `pg_trgm` extension enablement and the GIN trigram index on `songs.name`.
- The semantics of "what `search` returns to the GraphQL client" (a heterogeneous list, never blended).
- Request-level specs for the `search` query.

## Where this feature ends

- **`Song`'s search scopes (`search`, `fulltext_search`, `fuzzy_search`) live in `features/songs/`.** Even though they exist *for* search, they are model behavior on `Song`. This feature consumes them (or, currently, fails to — see Patterns). Adding a new tier or changing weights happens in `app/models/song.rb` and its specs.
- **The `text_search` generated column, `immutable_array_to_string` SQL function, and the multi-column trigram GiST index live in `features/songs/`.** They are part of the Song schema. The GIN trigram index on `songs.name` is the one piece of search-specific schema owned here because it predates the `text_search` migration and was added explicitly to support search.
- **`YoutubeClient` and the YouTube API integration live in `features/youtube/`.** This feature calls `YoutubeClient#search`; it does not own the client, its credentials, or the `OpenStruct` shape it returns.
- **`LibraryRecord` lives in `features/music-library/`.** This feature reads `LibraryRecord.select(:song_id).where(user:)` for exclusion but does not own the join table.
- **The `search` field's *declaration* and `confirm_current_user!` line live in `app/graphql/types/query_type.rb`** (documented under `structures/resources.md`). This feature owns the body the field calls into, not the field plumbing.
- **`Tag`, `TagLibraryRecord`, and tag-driven discovery live in `features/tagging/`.** Tag matching is currently subsumed by `songs.youtube_tags` (a string array on the song), not the `Tag` model. See "Do not build" below.

## Extension points

- **A new searchable entity (e.g., adding `Playlist` or `Tag` to search results).** Add the model as a new branch in `Selectors::SearchResults#search`, add the type to `Types::SearchResultType.possible_types`, add a `when ModelClass` branch to `resolve_type`, and update `spec/queries/search_spec.rb` to cover the new branch. **If the new entity's text search needs to participate in the same 3-tier ranking, give it its own `search` scope on its own model** (mirror the pattern in `Song.search`) rather than centralizing rank logic in the selector — that keeps Postgres planning per-table and the indexes co-located with the schema.
- **A new ranking tier on `Song.search`.** Edit `app/models/song.rb` (under `features/songs/`). Add the tier's predicate as another `OR` in the `WHERE`, insert the tier into both `CASE` arms in the `ORDER BY`, and update `spec/models/song_spec.rb`. If the tier needs a new index, roll a migration — name it explicitly under `db/migrate/` rather than amending an existing search migration.
- **Wire the selector to use `Song.search` instead of ILIKE-on-name.** Replace `Song.where(Song.arel_table[:name].matches("%query%"))` with `Song.search(query)` in `from_all_songs`. Then re-confirm `spec/queries/search_spec.rb` (the current spec is written to ILIKE semantics — the "song" → `other-song` match passes either way, but any future test that depends on tier ordering will need to follow this change).
- **Result pagination.** The `search` field currently returns a plain array. To paginate, switch the GraphQL field to a `connection_type` (or implement cursor pagination by hand on the selector) and slice in the selector — the trigram operators support `ORDER BY similarity DESC LIMIT N` efficiently because the GiST index supports `<<->` ordering.
- **Plumbing the unused `lookahead`.** `Selectors::SearchResults` already accepts and stores it. To enable N+1 prevention, inspect `@lookahead.selection(:song).selects?(:library_records)` (or similar) inside `from_all_songs` and `.includes(:library_records)` conditionally.

## Do not build here

- **Do not add Elasticsearch, OpenSearch, Meilisearch, Algolia, Typesense, or any external search index.** The Postgres `pg_trgm` + `tsvector` path is intentional. Adding an external index introduces a sync problem (background indexer, eventual consistency, deploys must include reindex steps, environments diverge) that the team has not chosen to take on. The 3-tier scope on `Song.search` is the chosen ceiling for ranking sophistication.
- **Do not search `Tag` or `LibraryRecord` directly.** Tag matching is currently delegated to the `youtube_tags` text array column on `Song`, included in the `text_search` tsvector (weight `B`) and the multi-column trigram expression. Searching the `Tag` model or `tag_library_records` table would create two parallel discovery paths — pick one. If product wants user-applied tags to drive search hits, extend `text_search`'s expression to include them (and roll a new migration to regenerate the column) rather than adding a new selector branch.
- **Do not search `LibraryRecord`** — it has no user-facing text fields. If you need to expose a library-only filter (e.g., "search inside my library"), add a parameter to the existing `search` field and branch in the selector; don't add `LibraryRecord` to the result union.
- **Do not blend local and YouTube results in a single response.** Local-first / YouTube-fallback is a product decision, not a quirk. Mixing the two would force the client to disambiguate "is this song already in our catalog?" on every result. Keep the union and keep the all-or-nothing branch.
- **Do not return raw `OpenStruct` from any new selector path without updating `SearchResultType.resolve_type`.** The `when OpenStruct` branch is fragile — it's only true today because the only `OpenStruct` flowing through is the YouTube payload. If you start emitting `OpenStruct` from somewhere else, dispatch will misclassify.
- **Do not call `Song.search` outside of `Selectors::SearchResults` (or wherever the search field lives).** It's expensive — three predicates and a CASE-based ORDER BY. Other call sites that need a simpler match should use `Song.fuzzy_search` or `Song.fulltext_search` individually, or write an ILIKE.
- **Do not paginate by `OFFSET`.** Trigram and tsvector queries can be expensive enough that `LIMIT N OFFSET M` for large M is pathological. Use keyset pagination on `(tier, score, id)` if pagination is added.

## Schema invariants

- The `pg_trgm` extension must remain enabled. Disabling it would break the GIN index on `songs.name`, the GiST multi-column index, and every `<%` / `<<->` operator.
- The `immutable_array_to_string(text[], text)` SQL function must remain `IMMUTABLE`. Both the `text_search` generated column and the GiST multi-column index reference it; dropping it cascades.
- `songs.text_search` is `GENERATED ALWAYS AS (…) STORED`. It cannot be assigned by the application. Adding to it requires dropping and recreating the column.
- The order of `setweight` calls in the `text_search` expression encodes search-relevance priority (`A` > `B` > `C` > `D`). Changing weights is a search-behavior change, not a schema change — coordinate with whoever owns ranking quality.

## Test boundary

Specs owned by this feature are limited to `spec/queries/search_spec.rb`. The scope-level coverage of ranking, fuzzy matching, and the `text_search` column lives in `spec/models/song_spec.rb` under `features/songs/`. If you change ranking, update both.
