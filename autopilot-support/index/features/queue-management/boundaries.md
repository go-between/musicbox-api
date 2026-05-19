# Queue Management — Boundaries

## Extension points

- **New advancement triggers** (skip, force-next, admin nudge) should enqueue `QueueManagementWorker.perform_async(room_id)` directly after toggling the relevant `Room` state. The worker's `queue_processing?` / `playing_until` guards keep it safe to call ad-hoc; just remember the poller will *not* claim a room with `playing_until` still in the future, so a force-skip needs to clear or backdate `playing_until` first.
- **Alternative scheduling** (e.g., replacing Clockwork with Sidekiq-Cron, AWS EventBridge, or an in-process scheduler) only needs to call `RoomQueuePoller.new.poll!` on whatever cadence is desired. The poller has no Clockwork coupling. Cadence change is a knob in `config/clock.rb` (`every(1.second, "room-poll")`).
- **New selection conditions** for which rooms need advancement go in `RoomQueuePoller`'s private scope builders (`newly_enqueued`, `recently_finished_playing`). Compose them with `.or` to preserve the single `update_all` claim step.
- **New post-advancement side effects** plug in as additional `*.perform_async` calls in `QueueManagementWorker#perform`, alongside the existing broadcast fan-out. Keep them outside `update_room!` so they only fire when advancement actually happened.

## Do-not-build

- **Do not tie playback timing to this worker.** The worker does not "play" a song — it only records that the room *should be* playing one and broadcasts the change. Clients drive actual playback off the `NowPlaying` channel; that responsibility lives in **real-time-playback**.
- **Do not introduce a parallel queue table.** The `room_queues` migration and its rename to `room_songs` are historical; the queue today is the `waiting`-state subset of `room_playlist_records`. New queue features extend that model, not a sibling table.
- **Do not write `queue_processing` or `playing_until` from outside `Room#idle!` / `Room#playing_record!` / the poller's claim step.** The 1Hz idempotency contract depends on exactly those three sites managing the flag. The poller is the only allowed *setter* to `true`; the worker (via `Room` helpers) is the only allowed *clearer*.
- **Do not call `QueueManagementWorker.perform_async` from request controllers without first ensuring the room's flags reflect intent.** The worker's first action inside the lock is to bail if `queue_processing?` is false — silent no-ops are easy to create here.
- **Do not loosen the row lock** in `update_room!`. The lock is what keeps a manual trigger from racing the poller.

## Where queue-management ends

- **Playlist mutation** — selecting *which* record plays next, ordering, rotation fairness, and the `waiting` / `played` state machine on `RoomPlaylistRecord` belong to **playlist-management**. This feature only consumes `RoomPlaylistGenerator` and writes `play_state: "played"` + `played_at` on the advancing record.
- **NowPlaying broadcast and the `NowPlaying` channel** belong to **real-time-playback**. This feature fires `BroadcastNowPlayingWorker` but owns nothing about the broadcast payload, the channel, or client synchronization.
- **Playlist broadcast** belongs to **playlist-management** (`BroadcastPlaylistWorker`). This feature triggers it on advancement but does not own it.
- **Team broadcast** (active-room change, room idling visibility on the team) belongs to **teams**. This feature triggers `BroadcastTeamWorker` after advancement but does not own its payload.
- **The `waiting_songs` write path** from playlist mutations lives in **playlist-management**. This feature only reads the flag in the poller.
- **`Room#idle!` and `Room#playing_record!`** are defined on the `Room` model and conceptually belong to **rooms**, but they exist almost exclusively to serve this feature. Changes to them should be coordinated with this feature's invariants (clearing `queue_processing`, deriving `playing_until` from song duration).
