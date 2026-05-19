# Playlist Management — Patterns

## RoomPlaylistRecord is the join, not Room.songs
- The Room <-> Song relationship goes through `RoomPlaylistRecord` exclusively. There is no `room.songs` direct association; everything (queued, played, ordering, listens) is a row in this table. Treat `RoomPlaylistRecord` as the unit of work whenever code talks about "the playlist."
- A row's role is determined by `play_state` (`waiting` vs `played`) and `played_at` (set only when transitioning to `played`). The GraphQL type exposes only `played_at`, not `play_state` — clients distinguish state by presence of `played_at`.
- `order` is **per-user**, not per-room. Two users can both have a record with `order: 0`; the rotation interleaves them. This is why `RoomPlaylistRecordsAdd` reads `latest_record` filtered by `user: current_user` before appending.

## Generator builds the playlist from Room#user_rotation
- `RoomPlaylistGenerator#playlist` is the canonical view of "what's coming up." It is not a DB ordering — it is a Ruby-side interleave of the rotation array.
- Algorithm: take the rotation, rotate it so the user *after* `room.current_record.user_id` is first, then for each round-robin position fill in that user's next waiting song. The result is a flat array where slot `n` is `rotation[(n) % rotation.size]`'s `n / rotation.size`-th waiting song.
- The generator runs `room.with_lock` even though it is read-only — it is reading `current_record` and `user_rotation` together, and the lock prevents a queue advance from happening mid-build.
- When `user_rotation` is empty the playlist is empty. Adding a record via `RoomPlaylistRecordsAdd` or `RoomPlaylistRecordsReorder` enrolls the current user in the rotation as a side effect (`ensure_user_in_rotation!`).

## Selector composition for queries
- `Selectors::RoomPlaylistRecords` is the only thing wired into the `roomPlaylist` GraphQL query. It receives a `lookahead` and resolves it into `RoomPlaylistRecord.includes(...)` for the requested associations (`:record_listens`, `:song`, `:user`) — this is how the selector avoids N+1 without forcing eager loading on every call.
- The same selector branches on the `historical:` argument: historical reads go straight to AR (`played` scope, `played_at desc`, optional `from` filter), while the future view delegates to the generator. The selector is the seam — neither caller knows which branch produced its rows.
- The historical path is the reason for the `played_at` index migration (`20200407040051_add_played_at_index_to_room_playlist_records.rb`). Any new query that filters or orders by `played_at` should ride that index.

## Mutation semantics — append vs replace
- `RoomPlaylistRecordsAdd` is **append-only**: it computes `starting_order` from the user's current max waiting `order` and assigns sequential indices. It never reorders existing rows. The `with_lock` protects the order-read-then-write race.
- `RoomPlaylistRecordsReorder` is **destructive replace**: the input list is treated as the new full ordering of the user's waiting records. Anything not present is `destroy_all`'d, scoped tightly by `user: current_user`, `room: current_user.active_room_id`, `waiting` state. Played records and other users'/rooms' records are untouched by design — this is asserted in spec.
- Reorder accepts mixed entries: items with `roomPlaylistRecordId` are updated; items with only `songId` create new records. Items that cannot be processed (nonexistent song, record owned by another user) are silently skipped; the resulting `order` values are allowed to have gaps (e.g., 1 and 3). "Relative ordering is fine" is the documented contract.
- `RoomPlaylistRecordDelete` is single-record and owner-scoped via the `find_by(id:, user:)` pattern. Cross-user delete attempts return `"Can't find song to delete"` (not a permission error string).
- `RoomPlaylistRecordAbandon` does **not** delete or mutate the playlist record at all — it sets `Room#playing_until` to 1 second ago. The actual queue advancement is in queue-management; this mutation is a "skip my current song" signal.

## Broadcast fan-out
- Three mutations (`add`, `reorder`, `delete`) explicitly enqueue `BroadcastPlaylistWorker.perform_async(room_id)`. `abandon` deliberately does not (the queue worker will broadcast after it advances).
- The worker re-executes the `roomPlaylist` GraphQL query with `override_current_user: true` — it does not call the selector directly. This means broadcasts always reflect the post-commit DB state and any future GraphQL-layer logic added to the field is honored.
- The broadcast carries a fixed GraphQL projection (`id, order, song { id, durationInSeconds, name, thumbnailUrl, youtubeId }, user { id, email, name }`). Subscribers receive exactly this shape; changing it is a client contract change.
- `RoomPlaylistChannel` itself is an empty class — the channel exists solely as a topic identifier; subscription/auth logic is in `ApplicationCable`.

## Locking and waiting_songs flag
- Both `add` and `reorder` wrap the write in `room.with_lock` and flip `Room#waiting_songs` to true if it isn't already. That flag is read by queue-management; this feature owns flipping it on, queue-management owns flipping it off.
