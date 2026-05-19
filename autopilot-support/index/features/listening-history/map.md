# Listening History — Map

## Model
- `app/models/record_listen.rb` — User-song play log; `belongs_to :room_playlist_record, :song, :user`. Schema-level `unique_record_listens` index enforces one row per `(room_playlist_record_id, song_id, user_id)` triple; the `approval` integer is updated in place rather than appending new rows.

## GraphQL
- `app/graphql/mutations/record_listen_create.rb` — Single write path. Rejects when the supplied `record_id` is not the caller's `active_room.current_record_id`; upserts the listen via `find_or_create_by!` with a `RecordNotUnique` fallback; clamps `approval` to `0..3`; enqueues `BroadcastRecordListensWorker`.
- `app/graphql/types/record_listen_type.rb` — Exposes `id`, `approval`, `room_playlist_record`, `song`, `user`. No timestamps surfaced.

## Realtime
- `app/channels/record_listens_channel.rb` — Empty ActionCable channel (no `subscribed`/`unsubscribed` callbacks); transport surface only. Broadcasts are triggered by the worker via `RecordListensChannel.broadcast_to(room, ...)`.

## Workers
- `app/workers/broadcast_record_listens_worker.rb` — Re-runs the `recordListens` GraphQL query for the room's current record with `override_current_user: true`, then broadcasts the rendered result to the room. Queue: `broadcast_record_listens`.

## Migrations
- `db/migrate/20200318014102_create_listens_table.rb` — Creates `record_listens` with uuid PK and per-FK indexes on `room_playlist_record_id` and `song_id` only (no `user_id` index).
- `db/migrate/20200603024043_add_unique_constraint_on_record_listens.rb` — Data migration that destroys all-but-most-recent duplicates per `(room_playlist_record_id, song_id, user_id)` before adding the `unique_record_listens` unique index. `down` raises `IrreversibleMigration`.

## Specs
- `spec/models/record_listen_spec.rb` — Smoke test that the three `belongs_to` relations round-trip.
- `spec/mutations/record_listen_create_spec.rb` — Covers create, update-in-place on existing listen, and the `ActiveRecord::RecordNotUnique` fallback path; asserts worker enqueue in every success case.
- `spec/queries/record_listens_spec.rb` — Exercises the `recordListens(recordId:)` query (resolver lives on `Types::QueryType`, not in this feature's CSV scope).
- `spec/workers/broadcast_record_listens_worker_spec.rb` — Uses `have_broadcasted_to ... from_channel(RecordListensChannel)` to assert payload shape and per-user approval values.
