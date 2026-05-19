# Step 14 — features/real-time-playback/

- id: 14
- kind: produce
- verify: pass

## Changes

Wrote the three-file index for the `real-time-playback` feature:

- `autopilot-support/index/features/real-time-playback/map.md` — covers every CSV-listed file: `app/channels/now_playing_channel.rb`, `app/workers/broadcast_now_playing_worker.rb`, `db/migrate/20190606130002_add_play_state_and_played_at_to_room_songs.rb`, `db/migrate/20200205052424_add_playing_until_to_room.rb`, and `spec/workers/broadcast_now_playing_worker_spec.rb`. Each entry notes the non-obvious role (no-body channel inherits room-scoping; worker re-runs hardcoded GraphQL query; `playing_until` is server-only).
- `autopilot-support/index/features/real-time-playback/patterns.md` — documents (1) the room-keyed empty-channel pattern shared across `broadcast_*` channels, (2) why the broadcast payload is the raw GraphQL response shape, (3) the client-side clock-sync model using `playedAt + durationInSeconds` (no re-sync, no heartbeat), (4) the queue-advance trigger path from Clockwork through `RoomQueuePoller` → `QueueManagementWorker` → `BroadcastNowPlayingWorker`, and (5) the `play_state`/`played_at` write-together invariant.
- `autopilot-support/index/features/real-time-playback/boundaries.md` — names the four neighboring features (`queue-management`, `playlist-management`, `youtube`, `user-authentication`) and where each takes over; lists extension points (payload fields, new sync channels, new playback-origin columns) and do-not-build items (client-driven timing, song-keyed subscriptions, periodic re-sync, calling the worker from mutations, surfacing `playing_until` to clients, giving `NowPlayingChannel` a body).

## Verify Result

- `test -s` for all three files — pass (no `EMPTY:` lines).
- Every CSV basename present in `map.md` — pass (no `MISSING in map:` lines).
- `grep -nE ':[0-9]+'` line-number scan — pass (no matches; no line numbers leaked).

## Notes

- Index rules obeyed: pointed to files by path/symbol, no code blocks, no line numbers, only non-obvious info (no rephrasing of what the code says).
- Cross-references made to `structures/modules.md` (broadcast_* family), `structures/infrastructure.md` (clockwork vs rake poller), and to sibling features (`queue-management`, `playlist-management`, `youtube`, `user-authentication`) at their boundaries.
- Did not modify `progress.json`, `app/`, `lib/`, `db/`, `config/`, or `spec/`.
