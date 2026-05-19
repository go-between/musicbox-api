# Queue Management — Map

## Polling

- `app/lib/room_queue_poller.rb` — selects rooms that need queue advancement (either `playing_until` has passed, or `waiting_songs: true` with no current playback), flips them to `queue_processing: true` in a single `update_all`, and enqueues a `QueueManagementWorker` for each. Invoked from the Clockwork process.

## Workers

- `app/workers/queue_management_worker.rb` — advances a single room. Loads the room, takes a row lock, no-ops unless `queue_processing?` is set and `playing_until` is in the past, asks `RoomPlaylistGenerator` for the next waiting record, marks it played and calls `Room#playing_record!` (or `Room#idle!` if nothing is waiting). On success fans out `BroadcastTeamWorker`, `BroadcastNowPlayingWorker`, and `BroadcastPlaylistWorker`.

## Schema

- `db/migrate/20190322030346_create_room_queues.rb` — original `room_queues` table (room/song/user/order). Renamed to `room_songs` the following month and ultimately superseded by `room_playlist_records`; the table is no longer the queue substrate.
- `db/migrate/20200205061306_add_waiting_songs_to_room.rb` — adds the `waiting_songs` boolean flag on `rooms` that the poller uses to detect freshly-enqueued playlists with no active playback.
- `db/migrate/20200223055015_add_queue_processing_to_room.rb` — adds the `queue_processing` boolean flag on `rooms` (default `false`); the poller sets it and the worker clears it on `playing_record!` / `idle!`.

## Specs

- `spec/lib/room_queue_poller_spec.rb` — enumerates which `(playing_until, waiting_songs, queue_processing)` triples enqueue and which are skipped; the canonical reference for the selection rules.
- `spec/workers/queue_management_worker_spec.rb` — covers empty-queue idling, the "already playing" and "not processing" no-ops, transition to the next record, played-at stamping, `playing_until` derivation from song duration, broadcast fan-out, and `user_rotation` pruning of stale users.
