# Playlist Management — Map

## Model
- `app/models/room_playlist_record.rb` — the Room x Song x User join with `order` and a `play_state` enum (`waiting` / `played`). The single source of truth for "what songs are queued / have been played in a room"; also `has_many :record_listens`.

## GraphQL Types
- `app/graphql/types/room_playlist_record_type.rb` — exposes `id`, `order`, `played_at`, `record_listens`, `room`, `song`, `user`. `played_at` is the only nullable field — its presence is how clients tell played from waiting in this type.

## GraphQL Mutations
- `app/graphql/mutations/room_playlist_records_add.rb` — append-only batch add for the current user, increments `order` from the user's current max waiting record; also enrolls user in `Room#user_rotation` and flips `Room#waiting_songs` to true.
- `app/graphql/mutations/room_playlist_records_reorder.rb` — destructive reorder; treats the input as the new full ordering of the user's waiting records and destroys any waiting record for the user/room not present in the input.
- `app/graphql/mutations/room_playlist_record_delete.rb` — owner-scoped single-record delete by id; fires `BroadcastPlaylistWorker`.
- `app/graphql/mutations/room_playlist_record_abandon.rb` — does not touch a record; sets the active room's `playing_until` to 1 second ago, letting the queue worker advance.

## Generator / Selector / Channel / Worker
- `app/lib/room_playlist_generator.rb` — produces the interleaved upcoming playlist by walking `Room#user_rotation` and ordering each user's waiting records by `order`.
- `app/lib/selectors/room_playlist_records.rb` — query-time gate: branches between historical (DB-ordered by `played_at`) and future (delegates to `RoomPlaylistGenerator`); resolves GraphQL lookahead into `includes`.
- `app/channels/room_playlist_channel.rb` — empty subclass; only used as the broadcast topic identified by Room GlobalID.
- `app/workers/broadcast_playlist_worker.rb` — executes an inline GraphQL query against `roomPlaylist` and broadcasts the result to `RoomPlaylistChannel` for the room.

## Migrations
- `db/migrate/20190409022601_rename_room_queues_to_room_songs.rb` — first rename: `room_queues` -> `room_songs`. Historical breadcrumb that "queue" was the original name; do not reintroduce.
- `db/migrate/20190927232332_rename_room_songs.rb` — `room_songs` -> `room_playlist_songs`.
- `db/migrate/20190927233126_rename_room_playlist_songs.rb` — `room_playlist_songs` -> `room_playlist_records`. The current table name.
- `db/migrate/20200407040051_add_played_at_index_to_room_playlist_records.rb` — adds the `played_at` index that hot-paths the historical selector and listening-history queries.

## Specs
- `spec/factories/room_playlist_record.rb` — defaults to `order: 1`, `play_state: "waiting"`; no `played_at` (callers must set it for "played" rows).
- `spec/models/room_playlist_record_spec.rb` — relationships + enum state; no validation/scope coverage (consistent with repo convention).
- `spec/mutations/room_playlist_records_add_spec.rb` — confirms append order and starting-from-max behavior.
- `spec/mutations/room_playlist_records_reorder_spec.rb` — covers reorder, deletion of absent records, mixed new+existing entries, user-rotation enrollment, and the "ignore unprocessable" semantics (gaps in `order` are accepted).
- `spec/mutations/room_playlist_record_abandon_spec.rb` — three guard paths: not in room, no current record, not owner.
- `spec/mutations/room_playlist_record_delete_spec.rb` — owner-scoped deletion; asserts `BroadcastPlaylistWorker.perform_async` is enqueued.
- `spec/lib/room_playlist_generator_spec.rb` — interleaving correctness when `current_record` is set; empty-rotation fallback.
- `spec/workers/broadcast_playlist_worker_spec.rb` — drives the full broadcast end-to-end and asserts the interleaved payload on `RoomPlaylistChannel`.
- `spec/queries/room_playlist_spec.rb` — `roomPlaylist` query: future ordering, historical reverse ordering by `played_at`, and the `from` filter (despite filename being "Messages Query").
