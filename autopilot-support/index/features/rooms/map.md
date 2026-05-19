# Rooms — Map

## Model
- `app/models/room.rb` — `Room` belongs to `team`, has many users via `active_room_id` (not `room_id`), has many `room_playlist_records` and `songs` through them; exposes `idle!` and `playing_record!` state transitions and an internal `playing_until_datetime` derived from the current record's song duration.

## GraphQL Mutations
- `app/graphql/mutations/room_create.rb` — creates a room scoped to `current_user.active_team`; relies on `belongs_to :team` to reject creation when the user has no active team (yields `"Team must exist"`).
- `app/graphql/mutations/room_activate.rb` — swaps the calling user's `active_room_id` and `active_team_id`, then enqueues `BroadcastTeamWorker`; team membership is enforced by the `Room.find_by(team: current_user.teams)` lookup.

## GraphQL Types
- `app/graphql/types/room_type.rb` — exposes `name`, `id`, `users`, `current_record`, and `current_song`; deliberately does not expose `user_rotation`, `playing_until`, `queue_processing`, or `waiting_songs` (server-side rotation/playback state).

## Migrations
- `db/migrate/20190218193526_create_room.rb` — base `rooms` table with uuid primary key and `name`.
- `db/migrate/20190218194925_add_room_to_user.rb` — adds `room_id` to `users` (later renamed; see below).
- `db/migrate/20190606125833_add_user_rotation_to_rooms.rb` — adds `user_rotation` as a Postgres `uuid[]` column with default `{}` (ordered DJ queue, not a join table).
- `db/migrate/20190928195833_update_room.rb` — renames `current_song_id` to `current_record_id` and drops `current_song_start` (room now points at a playlist record, not a song directly).
- `db/migrate/20191231013211_update_room_for_user.rb` — renames `users.room_id` to `users.active_room_id` (the "active room" framing is post-hoc).

## Factories
- `spec/factories/room.rb` — default factory leaves `current_record`, `playing_until`, and `waiting_songs` cleared; always builds a team association.

## Specs
- `spec/models/room_spec.rb` — covers the `users` / `room_playlist_records` / `songs` / `current_record` / `current_song` association graph.
- `spec/mutations/room_create_spec.rb` — documents the `active_team`-scoped create contract and the `"Team must exist"` / `"Name can't be blank"` error strings.
- `spec/mutations/room_activate_spec.rb` — asserts cross-team room activation is rejected and that `BroadcastTeamWorker` is enqueued on success.
- `spec/queries/room_spec.rb` — single-room visibility is constrained to rooms whose team the current user is on; unauthenticated requests get `unauthorized` rather than `nil`.
- `spec/queries/rooms_spec.rb` — list query is scoped to `current_user.active_team` (not `teams`), so users with no active team see an empty list.
