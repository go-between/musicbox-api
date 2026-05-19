---
id: 18
kind: produce
verify: pass
---

## Changes
- Created `autopilot-support/index/features/listening-history/map.md` covering all eleven CSV-classified files grouped by layer (model, GraphQL, realtime channel, worker, migrations, specs).
- Created `autopilot-support/index/features/listening-history/patterns.md` covering the "one listen per `RoomPlaylistRecord`" dedup window enforced by `unique_record_listens`; the `current_record_id` gating in `RecordListenCreate`; the `find_or_create_by!` + `RecordNotUnique` race-safe upsert idiom; `approval` clamping; the worker's `override_current_user: true` GraphQL re-execution pattern; the silent drop when the current record has rolled off; the empty `RecordListensChannel` as a thin transport; the query resolver living on `QueryType` (out of CSV scope) plus the `room_playlist_record_type`/selector includes; and the seam into `musicbox_unwound`/`unwound` for stats.
- Created `autopilot-support/index/features/listening-history/boundaries.md` capturing extension points (new context columns must extend the unique index; new reactions edit the existing row; new triggers reuse the broadcast worker pattern; new subscribers reuse `RecordListensChannel`), do-not-build rules (no stats aggregation here, no recommendation signal generation here, no listen creation for non-current records, no per-event play tracking, no bypassing the unique-index upsert path), and feature edges (music-statistics owns analytics reads; recommendations owns surfacing; real-time-playback owns `NowPlayingChannel`; playlist-management owns `RoomPlaylistRecord`; rooms owns `current_record_id`).

## Verify Result
- `test -s` on all three files: pass (no EMPTY output).
- CSV-basename presence check against `map.md`: pass (no MISSING output) — covered `record_listens_channel.rb`, `record_listen_create.rb`, `record_listen_type.rb`, `record_listen.rb`, `broadcast_record_listens_worker.rb`, `20200318014102_create_listens_table.rb`, `20200603024043_add_unique_constraint_on_record_listens.rb`, `record_listen_spec.rb`, `record_listen_create_spec.rb`, `record_listens_spec.rb`, `broadcast_record_listens_worker_spec.rb`.
- Line-number leak grep (`:[0-9]+` excluding http): pass (no matches).

## Notes
- The `recordListens(recordId:)` query resolver lives on `app/graphql/types/query_type.rb`, which the CSV classifies under a different feature; flagged this coupling in patterns because `BroadcastRecordListensWorker#query` depends on that resolver's shape.
- The unique index dedup window is per `RoomPlaylistRecord` (not per song or per day) — called this out as the non-obvious semantic of "what a listen is" since the model file itself is three associations and reveals nothing about uniqueness.
- The empty `RecordListensChannel` class is intentional: no `subscribed`/`unsubscribed` hooks, just a `broadcast_to(room, ...)` target. Documented as a transport-only seam rather than a bug.
- Worker uses `override_current_user: true` in GraphQL context; noted this as the codebase idiom for worker-originated GraphQL since there is no logged-in user inside Sidekiq.
- The 2020-06-03 migration's data-cleanup step (destroying duplicates by `(room_playlist_record_id, song_id, user_id)` keeping the most recent) is described in map.md as the prerequisite to the unique index — relevant if anyone considers rolling it back (`down` raises `IrreversibleMigration`).
