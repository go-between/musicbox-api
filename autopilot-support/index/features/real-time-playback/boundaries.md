# Real-time Music Playback — Boundaries

## Where this feature ends

- **Queue advancement** — choosing the next record, locking the room, updating `play_state`/`played_at`/`playing_until`, and detecting expiration lives in `features/queue-management/` (`QueueManagementWorker`, `RoomQueuePoller`, `config/clock.rb`, `lib/tasks/room.rake`). This feature only fires *after* queue-management has finished its update.
- **Playlist composition** — `RoomPlaylistGenerator`, the user-rotation logic, the add/reorder/abandon mutations, and the `RoomPlaylistChannel` broadcast all live in `features/playlist-management/`. The `playedAt`/`play_state` columns are read here but written there.
- **Skip-current-song** — `RoomPlaylistRecordAbandon` mutation sets `room.playing_until = 1.second.ago` and lets the poller pick it up. That mutation belongs to `features/playlist-management/`; this feature only sees the resulting broadcast.
- **Song metadata and duration** — `durationInSeconds` is sourced from `Song` (populated by YouTube ingestion in `features/youtube/`). If a song has the wrong duration, clients will stop early or late — fix it in the song record, not here.
- **Channel auth** — handled by `ApplicationCable::Channel#subscribed` and `ApplicationCable::Connection` (`features/user-authentication/`). This feature inherits room-scoping for free; do not add subscription guards here.

## Extension points

- **Adding fields to the broadcast payload** — edit the inline GraphQL query in `BroadcastNowPlayingWorker#query`. Anything resolvable on `room.currentRecord` (record, song, user) is fair game. Adding a new top-level field would require either a new query path or a new channel + worker.
- **A new synchronization channel** — if you need a separate stream (e.g., per-listener seek position, ad markers, reactions), follow the `broadcast_*` family pattern: empty channel subclass, dedicated worker on its own named queue, inline GraphQL query, `override_current_user: true` context. Enqueue from wherever the source-of-truth state mutation happens. See `autopilot-support/index/structures/modules.md` for the family.
- **A new playback origin** — if you need something other than `played_at` as the sync anchor (e.g., paused-and-resumed offsets), add a column to `room_playlist_records` and include it in the worker's GraphQL query. Do not encode it into `playing_until` — that column is owned by the poller's expiration scan.

## Do not build

- **Do not drive playback timing from the client.** The server is authoritative about *what* is playing and *when* it started (`playedAt`). Clients compute their own playhead but do not report it back, and do not request "seek to t=X". There is no resume / pause / seek protocol — adding one means rethinking `playing_until` semantics with `QueueManagementWorker`.
- **Do not tie real-time playback to specific songs.** The broadcast payload speaks in terms of the current `RoomPlaylistRecord` (with the song nested inside). Don't write code that subscribes to "song X is playing" — songs are reused across rooms and across records. Always go through the record.
- **Do not add a periodic re-sync broadcast.** Clients sync once at queue-advance time and one-shot-query on join. If you find yourself wanting a heartbeat, the right fix is usually a join-time fetch or a longer broadcast payload — not a recurring broadcast (which would multiply Sidekiq load by the number of active rooms).
- **Do not invoke `BroadcastNowPlayingWorker` from mutations or controllers.** Its only legitimate caller is `QueueManagementWorker`. Firing it elsewhere risks broadcasting stale state because the room may not yet be locked or the record may not yet be `played`.
- **Do not surface `rooms.playing_until` to clients.** It is a server-side scan column, not a sync timestamp.
- **Do not give `NowPlayingChannel` a body.** Subscription params, per-room filters, or custom `subscribed` logic break the inherited room-scoping pattern and will diverge from the rest of the `broadcast_*` family.
