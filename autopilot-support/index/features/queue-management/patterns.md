# Queue Management — Patterns

## Clockwork-driven 1Hz polling

- `config/clock.rb` runs `RoomQueuePoller#poll!` every second from a dedicated Clockwork process (see `structures/infrastructure.md`). There is no per-room timer or ActiveSupport-scheduled job; advancement latency is bounded by this tick.
- The clock process is separate from the web and worker dynos. Stopping it stops all queue advancement silently — there is no fallback path.

## Two-condition room selection

- The poller picks rooms by OR-ing two disjoint conditions: `recently_finished_playing` (`playing_until <= now AND NOT queue_processing`) and `newly_enqueued` (`playing_until IS NULL AND waiting_songs AND NOT queue_processing`). The `queue_processing` guard is what makes the 1Hz poll idempotent — once a room is claimed, subsequent ticks skip it until the worker clears the flag.
- Claiming happens via `Room.where(...).update_all(queue_processing: true)` *before* enqueuing the worker, and the relation is materialized to an array first because `update_all` clears the relation as a side effect (see the inline comment).

## `waiting_songs` is a hint, not a count

- `waiting_songs` is a boolean flag flipped to `true` by mutations that enqueue songs (`RoomPlaylistRecordsAdd`, `RoomPlaylistRecordsReorder`) and back to `false` only by `Room#idle!`. It is not authoritative — `RoomPlaylistGenerator` is what actually decides whether a next record exists. The flag exists so the poller can cheaply filter idle rooms with no work to do.

## Worker uses a row lock for serialization

- `QueueManagementWorker#update_room!` wraps everything in `room.with_lock`. Concurrent workers (e.g., a manual `perform_async` racing with the poller) are serialized at the DB row, so only one path through `playing_record!` / `idle!` runs at a time.
- Inside the lock, the worker re-checks `queue_processing?` and `playing_until&.future?` and bails on either — these are the guards that make the "did nothing because already playing" / "did nothing because not claimed" cases safe.

## `playing_until` is derived from song duration

- `Room#playing_record!` computes `playing_until` as `record.song.duration_in_seconds.seconds.from_now` at the moment of advancement. This is the *only* source of truth for when the current song ends; the poller reads it back on the next tick to decide whether to advance. There is no separate timer or broadcast that ends the song.

## Next-record selection delegates to the playlist generator

- The worker does not implement playlist ordering. It calls `RoomPlaylistGenerator.new(room, relation).playlist.first`, which is the same generator that powers the playlist query — see **playlist-management**. Rotation logic, per-user fairness, and the meaning of `play_state: "waiting"` live there, not here.

## User rotation pruning on advancement

- `remove_stale_user_from_room!` removes the previous record's user from `room.user_rotation` only if they are no longer active in the room *and* have no remaining waiting records. This is the cleanup hook for users who left mid-song; the playlist generator relies on `user_rotation` to decide who plays next.

## Broadcast fan-out is fire-and-forget

- After a successful advancement (or successful idle transition), the worker enqueues three downstream broadcast workers. It does not wait for them and does not retry them as a group — Sidekiq retries each independently. The trio always fires together; partial fan-out is not a supported state.
