---
id: 13
kind: produce
verify: pass
---

## Changes
- Created `autopilot-support/index/features/queue-management/map.md` listing all seven CSV-classified files grouped by layer (polling, worker, schema migrations, specs); explicitly notes that `create_room_queues` is historical and the queue substrate today is `room_playlist_records`.
- Created `autopilot-support/index/features/queue-management/patterns.md` covering Clockwork 1Hz polling from `config/clock.rb`, the two-condition (`recently_finished_playing` / `newly_enqueued`) selection + atomic `update_all` claim via `queue_processing`, `waiting_songs` as a cheap hint rather than authority, the `room.with_lock` serialization, `playing_until` derivation from song duration in `Room#playing_record!`, next-record delegation to `RoomPlaylistGenerator`, `user_rotation` pruning, and the fire-and-forget broadcast fan-out trio.
- Created `autopilot-support/index/features/queue-management/boundaries.md` capturing extension points (new triggers via direct `perform_async`, alternative schedulers calling `poll!`, new conditions composing with `.or`, new side effects as additional `perform_async` calls), do-not-build rules (don't tie playback timing to this worker — that's real-time-playback; no parallel queue table; don't write `queue_processing`/`playing_until` outside the sanctioned three sites; don't loosen the row lock), and feature edges (playlist mutation in playlist-management; NowPlaying broadcast in real-time-playback; playlist broadcast in playlist-management; team broadcast in teams; `Room` helper methods live in rooms but serve this feature).

## Verify Result
- `test -s` on all three files: pass (no EMPTY output).
- CSV-basename presence check against `map.md`: pass (no MISSING output) — covered `room_queue_poller.rb`, `queue_management_worker.rb`, `20190322030346_create_room_queues.rb`, `20200205061306_add_waiting_songs_to_room.rb`, `20200223055015_add_queue_processing_to_room.rb`, `room_queue_poller_spec.rb`, `queue_management_worker_spec.rb`.
- Line-number leak grep (`:[0-9]+` excluding http): pass (no matches).

## Notes
- `config/clock.rb` is the only invocation site for `RoomQueuePoller.new.poll!`; called out as a single point of failure in patterns (stopping the clock dyno silently halts all advancement) without prescribing a fix.
- The `update_all`-before-enqueue ordering in the poller, plus the inline comment about `update_all` clearing the relation, is the non-obvious idempotency mechanism — surfaced in patterns rather than left for code-reading.
- `playing_until` derived from `song.duration_in_seconds` inside `Room#playing_record!` is the sole timing source; flagged in patterns and reinforced in boundaries as the reason this worker must not own playback timing.
- `room_queues` / `room_songs` table is dead substrate; called out in both `map.md` (under schema) and `boundaries.md` (do-not-build a parallel queue table) so the migrations don't mislead future readers.
- `waiting_songs` writes from `RoomPlaylistRecordsAdd` and `RoomPlaylistRecordsReorder` are referenced as belonging to playlist-management; this feature only reads the flag.
