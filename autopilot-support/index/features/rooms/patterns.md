# Rooms — Patterns

## Lifecycle: create vs. activate
- `RoomCreate` is a pure persistence step. It does not move the calling user into the room — creating a room never changes `active_room_id`. A client that wants the creator inside must follow up with `RoomActivate`.
- `RoomActivate` is per-user, not per-room. It mutates the caller's `User` (`active_room_id`, `active_team_id`); the `Room` row itself is not touched. "Joining" a room is therefore a User-side write, which is why `Room.users` is keyed by `active_room_id`.
- The activate mutation also flips `active_team_id` to match the room's team. This is the canonical way a user's active team changes via room navigation — clients do not need to call a team-activate mutation first.

## Team scoping
- Room visibility is layered by query:
  - `room(id:)` (single) — scoped to `current_user.teams` (any team the user is on).
  - `rooms` (list) — scoped to `current_user.active_team` only. Users with `active_team: nil` get an empty list, not all-teams-they-belong-to.
  - `roomActivate` — scoped to `current_user.teams`, matching the single-room query.
- `RoomCreate` always assigns `current_user.active_team`. There is no API to create a room in a non-active team; switching teams first is required.
- `Room` `belongs_to :team` is non-optional (default Rails 5+ behavior); deleting the team-less path is enforced by validation, not by a DB constraint check at the room layer.

## Playback / rotation state lives on Room
- `Room` carries the playback cursor: `current_record_id` (FK to `RoomPlaylistRecord`), `playing_until` (timestamp), `queue_processing` (bool), `waiting_songs` (bool). The room is the single source of truth for "what's playing right now."
- `user_rotation` is a Postgres `uuid[]` ordered list of user ids — the DJ rotation order, not a membership list. Membership is `users.active_room_id`. Treat `user_rotation` as a sequence; do not assume set semantics.
- `Room#idle!` clears the entire playback tuple atomically (`current_record`, `playing_until`, `queue_processing`, `waiting_songs`). `Room#playing_record!(record)` advances the cursor and computes `playing_until` from `record.song.duration_in_seconds.seconds.from_now`. Both wrap `update!`, so callers do not need to manage individual fields.
- `playing_until` is computed at write time from server clock + song duration. There is no recurring "tick" updating it — consumers compare against `Time.now` themselves.

## Activation broadcast
- After flipping the user's active room/team, `RoomActivate` enqueues `BroadcastTeamWorker` for the room's team. Real-time clients learn that membership changed via the team-level broadcast, not via a per-room channel write from the mutation.

## Relationships to neighboring features
- Playlist: rooms have many `room_playlist_records`; the `current_record` and `current_song` accessors traverse that join. The room owns the cursor; the join table owns the queue ordering.
- Queue advancement: the room exposes the levers (`queue_processing`, `playing_until`) but does not advance itself. The queue feature reads/writes these fields from outside.
- Messages: messages are per-room (a `Message belongs_to :room`); the room itself has no `has_many :messages` declaration here.
