# Search Functionality — Patterns

Non-obvious conventions for how search works in this app. The "what" lives in the code; this file is the "why" and "watch out for".

## Search is Postgres-native — there is no Elasticsearch, OpenSearch, or external index

Every search path in this app runs against the live `songs` table through SQL operators and indexes provided by the `pg_trgm` extension plus a stored `tsvector`. There is no background indexer, no document store, no out-of-band sync. If you are tempted to add Elastic / Meilisearch / Algolia, read `boundaries.md` first — the decision to stay in Postgres is intentional.

## The 3-tier ranking lives on `Song`, not in the selector

`Song.search` (in `app/models/song.rb`) is the canonical ranked-search scope. It UNIONs three search strategies via a single `WHERE … OR … OR …` and assigns each row a tier in the `ORDER BY`:

- **Tier 1 — full-text match.** `text_search @@ plainto_tsquery(query)` against the generated `text_search` tsvector column. Ordered within the tier by `ts_rank`.
- **Tier 2 — fuzzy trigram match.** `query <% (name || ' ' || channel_title || ' ' || tags)` using `pg_trgm`'s word-similarity operator. Ordered within the tier by `word_similarity` descending (closest first).
- **Tier 3 — ILIKE substring fallback.** Guarantees that any literal substring of the combined searchable text returns a hit even when the tokenizer (`'english'::regconfig`) strips it (stopwords, short fragments, punctuation-adjacent tokens).

A row only appears in the higher-tier set if it actually satisfies that tier's predicate; tiers 2 and 3 are recall safety nets, not re-ranks of tier 1. **The ordering shape (tier ASC, then per-tier score DESC) is what makes the contract feel like "best match first" without a heuristic global score** — don't replace the CASE with a weighted sum.

## The `text_search` column is generated, weighted, and indexed by a separate migration

`db/migrate/20251117092530_add_text_search_to_songs.rb` declares `text_search` as `GENERATED ALWAYS AS (…) STORED`. The expression composes four `setweight` calls in priority order:

- `'A'` — `name`
- `'A'` — `channel_title`
- `'B'` — `youtube_tags`
- `'C'` — `description`

Postgres maintains this column on every write to `songs` — application code never assigns it. The GIN index `index_songs_on_text_search` is what makes `@@ plainto_tsquery(…)` fast. If you add a new searchable column on `Song`, you must roll a new migration that drops and recreates `text_search`; you cannot `ADD COLUMN` to a generated column.

## The `immutable_array_to_string` SQL function exists only to make `youtube_tags` indexable

`array_to_string` is `STABLE`, not `IMMUTABLE`, which means it can't appear inside a generated column or a functional index. The migration defines a hand-rolled SQL wrapper marked `IMMUTABLE` to bypass this. It's referenced by both the `text_search` generated column and the GiST trigram index on the combined searchable expression. **Do not delete or rewrite this function** — every search index depends on it.

## Two trigram indexes exist for two different operators

- `index_songs_on_name` (GIN, `gin_trgm_ops`) — powers ILIKE / `%` / `<%` against `songs.name` **only**. Added by `db/migrate/20200226234654_add_gin_index_to_song_name.rb`.
- `index_songs_on_searchable_content_trgm` (GiST, `gist_trgm_ops`) — powers fuzzy operators (`<%`, `<<->`) against the combined `name || channel_title || tags` expression. Added by `db/migrate/20251117093000_add_multi_column_trigram_search.rb`.

GIN is faster for read, slower for write; GiST supports `<<->` distance ordering, which GIN does not. Both are kept because the queries that hit them are different.

## The selector currently bypasses the 3-tier scope

`Selectors::SearchResults#from_all_songs` calls `Song.where(Song.arel_table[:name].matches("%#{query}%"))` — a plain ILIKE on `name` only. It does not invoke `Song.search` and therefore does not get tsvector ranking, fuzzy fallback, or multi-column matching. The richer scopes on `Song` are tested in `spec/models/song_spec.rb` (under `features/songs/`) and are evidently intended to be wired into this selector. **If you "fix" the selector to call `Song.search`, also re-confirm the library-exclusion subquery and the no-result branch in `spec/queries/search_spec.rb`** — that spec currently asserts behavior consistent with the ILIKE path.

## Library-exclusion subquery — not a join

The selector uses `where.not(id: LibraryRecord.select(:song_id).where(user: user))`, which Rails compiles to a `NOT IN (SELECT …)`. This is correlated against the caller's `LibraryRecord` rows. It's intentionally not a `LEFT OUTER JOIN … WHERE library_records.id IS NULL` because the result set returns plain `Song` rows and we never want to JOIN-multiply the relation across library records. If you change this to a join, deduplicate explicitly.

## Local-first, YouTube-fallback ordering is product-driven

`#search` returns local songs if **any** match (`from_all_songs.present?`), otherwise falls back to the external YouTube search. Local and YouTube results are never blended in the same response. This is what makes `Types::SearchResultType` a union — clients have to handle both possible shapes, but only one is ever returned per query.

## The `OpenStruct` branch in `resolve_type` is load-bearing

`YoutubeClient#search` returns `OpenStruct` instances (not models, not POROs). `SearchResultType.resolve_type` dispatches on `Song` vs `OpenStruct`. If you ever turn the YouTube payload into a real class (e.g., `YoutubeResult.new(...)`), update the union resolver in lockstep — otherwise GraphQL will return null types and clients will see empty results without an error.

## `lookahead` is plumbed but unused

`Selectors::SearchResults#initialize` accepts a `lookahead:` and stores it; nothing reads it. `QueryType#search` passes `extras: [:lookahead]` to opt in. This is a hook for future N+1 prevention — if you eager-load associations conditional on requested fields, do it in the selector by inspecting `@lookahead.selects?(:field_name)`.

## Empty query short-circuits in two places

Both `QueryType#search` (`return [] if query.blank?`) and `Song.search` (`return none if query.blank?`) defensively return empty. The selector itself does not. This means a blank query never hits the database — and never hits the YouTube client either, which is what you want (YouTube's search API will gladly return its top videos for an empty string and silently exhaust quota).
