# Song Library — Patterns

## Identity is `youtube_id`
- A Song is uniquely identified by its `youtube_id`. There is no DB unique constraint; uniqueness is enforced at the application layer via `Song.find_or_initialize_by(youtube_id: ...)` in `Mutations::SongCreate#resolve`.
- The `youtube_id` index (see `db/migrate/20190322030217_add_index_to_songs.rb`) exists to make that lookup cheap, not to enforce uniqueness. Adding songs through any path other than `SongCreate` risks duplicates.
- `youtube_id` is the only `presence` validation on the model; everything else (name, description, duration, channel, tags) is YouTube-sourced and nullable.

## YouTube metadata is hydrated once, at create time
- `SongCreate#attrs_from_youtube!` only fires when the Song was just initialized (`unless song.persisted?`). Existing songs are never re-hydrated, even if YouTube data has changed.
- The hydration writes `description`, `duration_in_seconds`, `name`, `thumbnail_url`, `youtube_tags`, `channel_title`, `channel_id`, `published_at`, `category_id` in one `update!`. All of these come from `YoutubeClient#find` — there is no user-supplied path for any of them.
- `duration_in_seconds` is therefore authoritative-from-YouTube; do not expose it as a mutation input.

## Three-tier search (`Song.search`)
- The `text_search` column is a Postgres GENERATED tsvector (see `db/migrate/20251117092530_add_text_search_to_songs.rb`) with weighted fields: name and channel_title at weight A, youtube_tags at B, description at C. The migration also defines an `immutable_array_to_string` SQL function — required because `array_to_string` is not immutable enough for a generated column.
- `Song.search(q)` ORs three conditions and orders by tier:
  1. Full-text match against `text_search` (uses the GIN index on `text_search`), ordered by `ts_rank`.
  2. pg_trgm word_similarity (`<%` / `<<->`) over a `COALESCE`-joined expression of name + channel_title + tags.
  3. ILIKE substring over the same expression — guarantees a contains match even when the first two miss.
- `Song.fulltext_search` and `Song.fuzzy_search` are exposed separately for callers that want only one tier. `search` is the default; the spec pins its recall/ranking behavior.
- The `searchable_expr` deliberately qualifies column names with `songs.` to avoid ambiguity when scopes are chained from other tables.

## Library attachment is part of `SongCreate`
- `SongCreate` is not just a Song factory — it always (re)attaches the caller to the song via `LibraryRecord.find_or_initialize_by(song:, user: context[:current_user])`. Callers that need a Song without a library effect should not use this mutation.
- The optional `from_user_id` argument records attribution (`source: "saved_from_history"`, `from_user_id: ...`) only on the first attachment. Subsequent calls for an existing record do not overwrite source — the spec asserts this preserves the original "I added this myself" attribution.
- This is why `SongCreate` is the entry point used by recommendation acceptance and library-add flows: it idempotently produces (Song, LibraryRecord) without re-fetching YouTube.

## Test scaffolding
- `YoutubeClient` is always stubbed in `SongCreate` specs (`instance_double(YoutubeClient)`); the spec also asserts it is *not* called for existing songs — that absence is part of the contract.
- The model spec uses raw `create!` rather than the factory when exercising `.search`, so it can pin the exact field combinations against the weighted tsvector. The factory leaves YouTube-derived columns blank, which would make search assertions ambiguous.
