# Song Library — Boundaries

## Extension points
- New YouTube-sourced metadata fields plug in by adding a column migration (mirroring `db/migrate/20200415022511_add_youtube_details_to_songs.rb`), extending `SongCreate#attrs_from_youtube!`, and exposing the field on `Types::SongType`. If the field should be searchable, it must also be added to the generated `text_search` column — drop and recreate via a new migration; you cannot `ALTER` a GENERATED column's expression in place.
- New search modes belong on the `Song` model as additional named scopes alongside `fulltext_search` / `fuzzy_search` / `search`. Keep them parameter-shape compatible (`->(query)`) so callers can swap them. Reuse the `searchable_expr` pattern (qualified column names + `COALESCE`) when fuzzy/ILIKE matching across multiple columns.
- Tier composition lives entirely in `Song.search`; if a fourth tier or a different ranking is needed, change it in one place — callers do not need to know.
- Re-hydrating stale YouTube metadata (if ever needed) belongs in a worker that calls `YoutubeClient` and updates Songs in bulk — not in `SongCreate`, which is deliberately one-shot.

## Do-not-build
- Do not add per-user state (added_at, position, source, listen counts, favorited) to `songs`. That state belongs on `LibraryRecord` — see **music-library**. The `songs` table must stay global and user-agnostic.
- Do not call YouTube from this feature. All YouTube HTTP/parsing lives in `app/lib/youtube_client.rb` (the **youtube** feature). `SongCreate` only knows the method `YoutubeClient#find`.
- Do not add a unique DB index on `youtube_id`. The current `find_or_initialize_by` flow tolerates the non-unique index and is relied on by callers (recommendation accept, library add) that race on the same id. Promoting the index to unique would surface as `RecordNotUnique` in those flows.
- Do not validate or transform metadata fields (name, description, etc.) — they are YouTube's truth, written verbatim. Validations would break re-attach of pre-existing rows where YouTube has since updated a title.
- Do not write to `Song` outside `SongCreate` for the create path. Tests use `create(:song, ...)` to skip YouTube, but production code should not.

## Where Song Library ends
- The `LibraryRecord` join, library deletion, and library population logic are **music-library**, not here. `Song` is unaware of who owns it.
- `Tag` / `TagLibraryRecord` association live in **tagging**. Songs surface tags only via the `youtube_tags` array (YouTube-supplied), which is distinct from user-applied tags.
- `Recommendation` create / accept flows are **recommendations**. They call `SongCreate` to land the song, then build their own join rows.
- Search result wrapping (`SearchResultType`, multi-model search) lives in **search**. This feature owns the SQL primitives; **search** assembles the user-facing query.
- YouTube HTTP, video parsing, and quota concerns are **youtube** (`app/lib/youtube_client.rb`).
- Room-level "current song" coupling is on `rooms` (`current_song_id`, `current_song_start` — see `db/migrate/20190407020627_add_song_data_to_room.rb`), owned by **real-time-playback** and **rooms**, not here.
