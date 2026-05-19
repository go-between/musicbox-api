# Search Functionality — Map

What each file in this feature does. Paths are the canonical source; this file points at them.

## GraphQL

- `app/graphql/types/search_result_type.rb` — `Types::SearchResultType`. A `BaseUnion` over `SongType` and `YoutubeResultType`. `resolve_type` dispatches on Ruby class: `Song` → `SongType`, `OpenStruct` → `YoutubeResultType`. The `OpenStruct` branch is load-bearing — `YoutubeClient#search` returns `OpenStruct` (not a model), so changing that shape will break union resolution. The `search` query field itself is wired in `app/graphql/types/query_type.rb` (see `features/songs/` cross-references) and returns `[SearchResultType]`.

## Selector

- `app/lib/selectors/search_results.rb` — `Selectors::SearchResults`. The orchestration layer between `QueryType#search` and the data layer. Two-tier fallback: try the local Song catalog first (`from_all_songs`), and only if empty fall back to the external `YoutubeClient#search`. Excludes songs already in the caller's library via a `NOT IN (LibraryRecord.select(:song_id).where(user:))` subquery. Note: this file currently uses `Song.arel_table[:name].matches("%query%")` (a plain ILIKE on name only) — the richer 3-tier ranking lives on the `Song.search` scope in `app/models/song.rb` and is **not** invoked here. See patterns.

## Database

- `db/migrate/20200226234544_enable_pgtrgm_extension.rb` — Enables Postgres `pg_trgm`. Required by both the GIN trigram index on `songs.name` and the GiST trigram index on the multi-column searchable expression. Without this extension, none of the search scopes will load.
- `db/migrate/20200226234654_add_gin_index_to_song_name.rb` — Adds the GIN index on `songs.name` using `gin_trgm_ops`. Powers fast ILIKE / `%` and `<%` operators against the name column specifically. The newer `text_search`/multi-column trigram indexes (in `features/songs/`) **do not replace** this index — name-only ILIKE still hits this one.

## Tests

- `spec/queries/search_spec.rb` — Request spec for the GraphQL `search` query. Pins two contracts: (1) songs already in the caller's library are filtered out; (2) when no local songs match, the YouTube fallback is invoked and its `OpenStruct` results render as `YoutubeResult`. `YoutubeClient.new` is stubbed via `instance_double` — `client_double.search(query)` is the seam.

## See also (not owned by this feature)

- `app/models/song.rb` — Owns the `search` / `fulltext_search` / `fuzzy_search` scopes and the `text_search` tsvector column. Lives under `features/songs/`. Patterns below explain why search scopes live on the model rather than in the selector.
- `app/graphql/types/query_type.rb` — Defines `field :search` and `def search` that instantiates `Selectors::SearchResults`. Lives under `structures/resources.md`.
- `db/migrate/20251117092530_add_text_search_to_songs.rb` and `db/migrate/20251117093000_add_multi_column_trigram_search.rb` — The newer text_search tsvector column and multi-column trigram GiST index. Listed under `features/songs/` because they belong to the Song schema, but the search behavior they enable is documented in patterns.
