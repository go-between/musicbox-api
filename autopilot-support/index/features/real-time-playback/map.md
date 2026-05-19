# Real-time Music Playback — Map

This feature broadcasts the currently-playing record (song + start timestamp) to every client subscribed to a room, so clients can render synchronized playback without polling. It is intentionally tiny: a no-body channel, one worker that re-runs a GraphQL query and pushes the result, plus the two schema columns (`rooms.playing_until` and `room_playlist_records.{play_state,played_at}`) that other features read to know what "now playing" means.

## Files

- `app/channels/now_playing_channel.rb` — `NowPlayingChannel`. Empty class; inherits `subscribed` from `ApplicationCable::Channel` so it streams to `current_user.active_room`. The room-keyed stream is what makes "playback for *my* room" work without per-channel code.
- `app/workers/broadcast_now_playing_worker.rb` — `BroadcastNowPlayingWorker`. Sidekiq job on the `broadcast_now_playing` queue. Re-executes a hardcoded GraphQL query (`room.currentRecord` with `playedAt`, song details, and user) through `MusicboxApiSchema.execute` with `context: { override_current_user: true }` (skips auth), then calls `NowPlayingChannel.broadcast_to(Room.find(room_id), payload)`. Enqueued exclusively by `QueueManagementWorker` after a successful queue advance.
- `db/migrate/20190606130002_add_play_state_and_played_at_to_room_songs.rb` — adds `play_state` (string, indexed) and `played_at` (datetime) to what was then `room_songs` (now `room_playlist_records`). `played_at` is the wall-clock value the broadcast payload returns as `playedAt` and that clients use as the playback origin.
- `db/migrate/20200205052424_add_playing_until_to_room.rb` — adds `rooms.playing_until` (datetime, indexed). Computed by `Room#playing_record!` as `record.song.duration_in_seconds.seconds.from_now`; consumed by `RoomQueuePoller` to find rooms whose playback has expired. Not in the broadcast payload — clients derive end-time from `playedAt + durationInSeconds`.
- `spec/workers/broadcast_now_playing_worker_spec.rb` — single example asserting both the song name and `playedAt` survive the GraphQL round-trip, using RSpec's `have_broadcasted_to(room).from_channel(NowPlayingChannel)` matcher.
