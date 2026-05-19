# Step 12 — features/playlist-management/

- id: 12
- kind: produce
- verify: pass

## Changes

Wrote the three-file index for the **Playlist Management** feature:

- `autopilot-support/index/features/playlist-management/map.md` — every CSV-listed file (model, GraphQL type, 4 mutations, generator, selector, channel, worker, 4 migrations, 9 specs) with a one-line role grouped by layer.
- `autopilot-support/index/features/playlist-management/patterns.md` — non-obvious patterns: `RoomPlaylistRecord` as the only Room<->Song join; `RoomPlaylistGenerator` interleave driven by `Room#user_rotation` + `Room#current_record` (run inside `room.with_lock`); per-user `order` semantics; selector branching on `historical:` with lookahead-driven `includes`; `add` vs `reorder` semantics (append vs destructive replace); abandon-as-signal vs delete-as-mutation; broadcast worker re-executing the GraphQL query; `waiting_songs` flag handoff to queue-management.
- `autopilot-support/index/features/playlist-management/boundaries.md` — extension points (new ordering algorithms via the selector seam, new `play_state` enum values, new broadcast fields via the worker projection); do-not-build (queue advancement is queue-management; playback timing is real-time-playback; `RecordListen` writes are listening-history; direct `RoomPlaylistRecord` queries from other resolvers; reintroducing "queue"/"room_songs" names); explicit feature endings to songs, rooms, queue-management, real-time-playback, listening-history, music-library, user-authentication.

## Verify Result

- `test -s` on all three files: pass (no EMPTY lines).
- Basename coverage in `map.md`: pass (no MISSING lines for any of the 23 CSV rows).
- Line-number check (`grep -nE ':[0-9]+'` excluding `http`): pass (no matches).

## Notes

- Index rules obeyed: pointed to files by path; no line numbers; no code blocks; only non-obvious info (e.g., that `played_at` rather than `play_state` is what the GraphQL type exposes to distinguish state; that `room.with_lock` is taken in the read-only generator to fence against concurrent queue advance; that the historical `played_at` index from 2020 backs the selector's historical branch; that the broadcast worker re-runs the GraphQL query rather than calling the selector; that `LibraryRecord` creation is an intentional cross-feature side effect of `RoomPlaylistRecordsAdd`; that gaps in `order` after reorder are an accepted contract; that `spec/queries/room_playlist_spec.rb` is misnamed "Messages Query" but covers `roomPlaylist`).
- Did not modify `progress.json`, `app/`, `lib/`, `db/`, `config/`, or `spec/`.
- Reused the convention from `features/password-reset/` (the only pre-existing three-file feature index) for headings, voice, and density.
