---
id: 17
kind: produce
verify: pass
---

## Changes
- Created `autopilot-support/index/features/songs/map.md` covering every CSV-listed Song Library file: the model, the `SongCreate` mutation, `SongType`, the eight in-scope migrations, and the three spec files.
- Created `autopilot-support/index/features/songs/patterns.md` documenting `youtube_id` as the app-enforced identity (no DB unique constraint), the one-shot YouTube hydration in `SongCreate#attrs_from_youtube!`, the 3-tier `Song.search` (full-text on the generated `text_search` tsvector + pg_trgm fuzzy + ILIKE fallback) with field weights and the `immutable_array_to_string` helper, and the dual create-or-attach behavior of `SongCreate` (including `from_user_id` source stamping).
- Created `autopilot-support/index/features/songs/boundaries.md` describing extension points (new metadata fields require updating `text_search`, new search modes as sibling scopes), do-not-build rules (no per-user state on `songs` — that's `LibraryRecord`; no YouTube HTTP — that's `app/lib/youtube_client.rb`; no unique index on `youtube_id`), and the seams to **music-library**, **tagging**, **recommendations**, **search**, **youtube**, and **real-time-playback**.

## Verify Result
- `test -s` on all three files: pass (no EMPTY output).
- CSV-basename presence check against `map.md`: pass (no MISSING output) — covered `song_create.rb`, `song_type.rb`, `song.rb`, and all six in-scope migrations plus the three specs.
- Line-number leak grep (`:[0-9]+` excluding http): pass (no matches).

## Notes
- The CSV lists `20190322030217_add_index_to_songs.rb` as in-scope; the index it adds on `youtube_id` is non-unique, which is load-bearing because `SongCreate` relies on `find_or_initialize_by` and several callers race on the same id. Flagged this explicitly in both patterns and boundaries.
- The `text_search` generated column lives in a 2025 migration (`20251117092530_add_text_search_to_songs.rb`) that the bootstrap brief flagged via the `youtube_details` / `gin_index` filename hint. Captured the immutable_array_to_string helper detail since it is the kind of thing that surprises someone adding a new searchable column.
- The legacy `db/migrate/20190407020627_add_song_data_to_room.rb` modifies `rooms`, not `songs`. Kept it in `map.md` (it is in the CSV) but called out in `boundaries.md` that ownership of `current_song_id` lives with **rooms** / **real-time-playback**.
- The 2025 channel-info migration is not in the CSV row set for Song Library, so it is not listed in `map.md`; the YouTube channel fields it adds are mentioned only insofar as `SongCreate` hydrates them and `SongType` exposes them.
