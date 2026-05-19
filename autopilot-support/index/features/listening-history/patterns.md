# Listening History — Patterns

## What a "listen" actually is
- A `RecordListen` is not a per-playback event. The `unique_record_listens` index keys on `(room_playlist_record_id, song_id, user_id)` — the dedup window is the lifetime of a single `RoomPlaylistRecord` (one queued spin of a song in a room). Re-listening to the same song in a new queue entry creates a new row; re-rating mid-play updates the existing row in place.
- `approval` is the user's reaction to that one spin (0–3, clamped in the mutation). It is the only mutable field on the row after create; the row itself is the "did this user hear this record" signal.

## Mutation contract
- The mutation refuses any `record_id` that is not `current_user.active_room.current_record_id`. You cannot back-fill a listen for a record that has rolled off — listens only accrue for the room's currently playing record. Treat this as the security boundary, not just an input check.
- `ensure_record_listen!` uses `find_or_create_by!` and explicitly rescues `ActiveRecord::RecordNotUnique` (race between concurrent creates against the `unique_record_listens` index). The spec for that path is the canonical example of how to write race-safe upserts in this codebase against a unique index.
- `approval` is clamped via `ensure_approval_range` to `0..3`. Clients should not pre-validate; rely on server clamping.

## Broadcast fan-out
- `BroadcastRecordListensWorker` re-executes the `recordListens` GraphQL query through `MusicboxApiSchema.execute` with `context: { override_current_user: true }`. This is the codebase's idiom for worker-originated GraphQL: there is no logged-in user inside Sidekiq, so the resolver must opt out of `current_user` checks. Look for `override_current_user` in `app/graphql/musicbox_api_schema.rb`/resolvers when extending.
- The worker looks the room up by `Room.find_by(current_record_id: record_id)` and silently returns if no room currently has that record — so a late-arriving broadcast for a record that has already advanced is dropped, not retried.
- The broadcast payload is the full `recordListens` query result (with `user { id, email, name }`), shaped for room dashboards rather than for the listening user. `RecordListensChannel` is empty by design — there are no per-subscriber filters; every subscriber to the room channel sees every user's approval.

## Query resolver lives elsewhere
- The `recordListens(recordId:)` field is defined on `app/graphql/types/query_type.rb` (not classified into this feature in the CSV). The worker depends on that field staying named and shaped as it is — changing the query shape requires updating `BroadcastRecordListensWorker#query` in lockstep.
- `app/graphql/types/room_playlist_record_type.rb` exposes `record_listens` on the record type as well, and `app/lib/selectors/room_playlist_records.rb` includes `:record_listens` based on lookahead to avoid N+1.

## Seeds Music Statistics
- `app/lib/musicbox_unwound.rb` and `app/lib/unwound.rb` read `record_listens` directly (joining and grouping on `song_id`, `approval`, and the `(room_playlist_record.user_id != record_listens.user_id)` distinction between DJ and listener) to produce year-end stats. Listening History's job is to keep that table truthful; aggregation lives in **music-statistics**.
