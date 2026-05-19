# Listening History — Boundaries

## Extension points
- New per-play context (room, playback source, device) should be added as columns on `record_listens` plus selective inclusion in `Types::RecordListenType`. The unique key is `(room_playlist_record_id, song_id, user_id)` — any new dimension that should split listens (e.g., re-listens within the same record) must extend that index, not just the table.
- New reaction shapes (beyond the 0–3 `approval` scalar) belong on the existing row, edited in place by `RecordListenCreate`. Add the field, expand `ensure_approval_range`-style clamping in the mutation, and surface it on `Types::RecordListenType`. Do not introduce a sibling table that key-shares with `record_listens`.
- Additional broadcast triggers (e.g., on delete or on a new event type) should follow the `BroadcastRecordListensWorker` pattern: enqueue from the writing mutation, re-execute the canonical GraphQL query with `override_current_user: true`, broadcast to `RecordListensChannel`. Reuse the queue `broadcast_record_listens` only if the new work has the same priority profile.
- New subscriber audiences (team dashboards, presence panels) should subscribe to the existing `RecordListensChannel` on the room stream rather than introducing a parallel channel — the empty channel class is intentionally a thin transport.

## Do-not-build
- Do not aggregate listening stats here. Year-end summaries, top songs, listener vs DJ splits, and any "favorites" computations belong in **music-statistics** (`app/lib/musicbox_unwound.rb`, `app/lib/unwound.rb`). This feature owns the row; statistics owns the query.
- Do not reuse `RecordListen` as a recommendation signal source from within this feature. Recommendations read whatever upstream signal they need; see **recommendations** for the model and its own write path.
- Do not allow listens to be created for a record that is not the room's current playing record. The `record_playing?` check is a security/data-integrity boundary — bypassing it would let any user log a listen on any historical record they could name.
- Do not add per-event play tracking (every press of play, scrubs, partial listens) on this table. The row's semantic is "this user was present for this spin"; finer-grained events should live in a separate domain rather than being squeezed into approval levels or new columns.
- Do not assume the worker will retry indefinitely on a stale `record_id`. `BroadcastRecordListensWorker` returns silently when the room's current record has moved on; if you need at-least-once delivery for a listen, the storage row itself is the source of truth, not the broadcast.
- Do not bypass `find_or_create_by!` + `RecordNotUnique` rescue when writing listens. The unique index will reject concurrent creates; the established pattern in `RecordListenCreate#ensure_record_listen!` is the only sanctioned write path.

## Where listening history ends
- **Music Statistics** (`features/music-statistics/`) owns all reads-for-analytics of `record_listens`. If a question is "how many," "top N," or "over time," it lives there.
- **Recommendations** (`features/recommendations/`) owns surfacing songs to users. It may consume signals derived from listening history, but the schema, models, and write paths are its own.
- **Real-time Playback** (`features/real-time-playback/`) owns "what is playing now" via `NowPlayingChannel`. `RecordListensChannel` is adjacent but distinct: it carries the reactions for the currently playing record, not playback state itself.
- **Playlist Management** (`features/playlist-management/`) owns `RoomPlaylistRecord`. Listening History only points at it; lifecycle (create, reorder, abandon) is not this feature's concern. The `record_listens` `has_many` on `RoomPlaylistRecord` is declared there.
- **Rooms** (`features/rooms/`) owns `current_record_id` and the `active_room` concept the mutation gates on. Changes to how a room's "current record" is determined ripple here through the gating check.
