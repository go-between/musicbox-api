# Real-time Music Playback — Patterns

## Room-keyed stream, channel has no body

`NowPlayingChannel` is literally an empty subclass. Subscription routing is inherited from `app/channels/application_cable/channel.rb`, which does `stream_for current_user.active_room`. That means a client's subscription target is always "the room I am currently in" — there is no client-supplied room id, no `params[:room_id]` to validate. Switching rooms (changing `users.active_room_id`) requires the client to resubscribe to pick up the new stream. This pattern is shared with `MessageChannel`, `PinnedMessagesChannel`, `RecordListensChannel`, and `RoomPlaylistChannel`.

## Broadcast payload is the GraphQL response, not a hand-rolled DTO

`BroadcastNowPlayingWorker` re-runs an inline GraphQL query string through `MusicboxApiSchema.execute` and broadcasts `now_playing.to_h` directly. The result is the client receives the exact shape of a `room.currentRecord` query response (including the `data:` envelope and any `errors`) — the same shape it would get from an HTTP query. Clients can reuse the GraphQL response normalization they already have for queries.

This avoids drift between query and subscription payloads but couples the broadcast to the worker's hardcoded query string. Changing fields requires editing the heredoc in the worker's private `#query` method; see the broader pattern in `autopilot-support/index/structures/modules.md` under "broadcast_* family".

The worker authenticates by passing `context: { override_current_user: true }` rather than holding a real user — see `app/graphql/types/query_type.rb` for how that bypass works.

## Client-side clock sync via `playedAt`

The broadcast payload sends `playedAt` (when the record actually started playing) but **not** the song duration's end time. Clients compute their playhead as `now - playedAt` and stop when they hit `durationInSeconds` (also in the payload). This is the only synchronization mechanism — there is no periodic re-sync broadcast, no `currentPosition` field, no seek event. A late-joining client gets one `NowPlayingChannel` message at subscription time (because `QueueManagementWorker` doesn't fire on join) — for that case, clients must fall back to a one-shot `room.currentRecord` GraphQL query.

`rooms.playing_until` exists for the server's benefit only. It is the indexed column `RoomQueuePoller` scans every second to find expired playbacks. Do not surface it to clients as a sync source — it is server wall-clock and can drift from `playedAt + durationInSeconds` by milliseconds depending on enqueue latency.

## Broadcast is triggered by queue advancement, not by playback events

`BroadcastNowPlayingWorker.perform_async(room_id)` is enqueued from exactly one place: `QueueManagementWorker#perform` after it successfully advances the room (either to a new record or to idle). It is not called from mutations directly, not called on subscribe, not called on song-create. The implication: "now playing changed" and "the queue advanced" are the same event.

`QueueManagementWorker` is itself enqueued only by `RoomQueuePoller#enqueue_for`, which runs every second via `config/clock.rb` (`Clockwork.every(1.second, "room-poll")`). So the worst-case latency from "song finished playing" to "clients see the next song" is ~1s of poll latency plus Sidekiq scheduling on the `broadcast_now_playing` queue. The `room:poll_queue` rake task in `lib/tasks/room.rake` is an alternative 0.1s-interval poller that exists alongside Clockwork — see `autopilot-support/index/structures/infrastructure.md`.

## `play_state` and `played_at` as the source of truth

The `play_state` enum on `RoomPlaylistRecord` (`played` / `waiting`) is what `RoomPlaylistGenerator` uses to filter the queue — it is not derived from `played_at` being non-null. `QueueManagementWorker` sets both fields in one `update!` when promoting a record. Don't infer one from the other; both must be written together to keep the playlist projection consistent.
