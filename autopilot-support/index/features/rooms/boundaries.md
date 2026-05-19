# Rooms — Boundaries

## Extension points
- New scalar room fields (e.g., description, theme, max users) plug in as columns on `rooms` plus optional surface in `app/graphql/types/room_type.rb`. The existing playback fields (`playing_until`, `queue_processing`, `waiting_songs`) are deliberately *not* exposed in `RoomType` — follow that pattern for any server-side state.
- New room states are best modeled as additional `Room#…!` instance methods (mirroring `idle!` and `playing_record!`) that wrap a single `update!` of the relevant tuple. Avoid scattering partial updates across callers.
- New scope or filter mutations should reuse the `Room.find_by(team: current_user.teams)` (any team) vs. `Room.where(team: current_user.active_team)` (active team only) split — that distinction is the existing authorization vocabulary.
- Membership / presence changes belong on `User` (via `active_room_id`), not on `Room`. Add new "join" semantics by adding User-side writes plus a broadcast, as `RoomActivate` does.
- The `user_rotation` `uuid[]` column is the seam for any DJ-order feature. Append/remove with Postgres array ops or full overwrite; do not introduce a parallel join table.

## Do-not-build
- Do not bake playlist logic into `Room`. The `room_playlist_records` association is for traversal; queue ordering, adding songs, abandoning records, and reorder operations belong in **playlist-management**.
- Do not bake queue advancement into `Room`. `Room#playing_record!` and `idle!` are atomic transitions called *from* the queue worker — the room never schedules its own next song, polls itself, or owns the timing loop.
- Do not have `Room` write to channels directly. Activation enqueues `BroadcastTeamWorker`; any future room-state broadcast should go through the same worker pattern, not `ActionCable.server.broadcast` inline.
- Do not expose `user_rotation`, `playing_until`, `queue_processing`, or `waiting_songs` in `RoomType` without a deliberate cross-feature review. These are server-controlled and clients consume their effects via the now-playing channel.
- Do not let `RoomCreate` activate the creator's `active_room`. Create and activate are intentionally separate steps; collapsing them would break the "create in active team, then join" client flow.
- Do not introduce ownership / role columns on `Room` (no `owner_id`, no admin flags). Authorization is mediated through team membership and `active_team` — adding room-level roles would fork the auth model.

## Where rooms ends
- **playlist-management** owns `RoomPlaylistRecord` (the join), including add/reorder/abandon mutations and the playlist generator. `Room` only reads the join to expose `current_record` and `current_song`.
- **queue-management** owns the queue advancement worker and the poller. It calls `Room#idle!` and `Room#playing_record!` from outside; those methods belong to this feature, but the scheduling logic does not.
- **real-time-playback** owns `NowPlayingChannel` and the broadcast worker that pushes room playback state to clients. The room model holds the state; the channel feature ships it.
- **messages** owns `Message` (which `belongs_to :room`). The Room model does not declare the inverse association; if you need to enumerate a room's messages, query `Message` directly.
- **teams** owns `Team`, `TeamUser`, and the `active_team` activation surface. `Room.team` is a non-optional belongs-to into that feature; team lifecycle and membership questions stop at the team boundary.
- **user-authentication** owns `users.active_room_id` as a column on `User`; rooms-feature code writes to it (via `RoomActivate`), but the column, its index, and the `has_many :users` inverse live with the user model.
