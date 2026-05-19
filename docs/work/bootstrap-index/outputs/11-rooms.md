---
id: 11
kind: produce
verify: pass
---

## Changes
- Created `autopilot-support/index/features/rooms/map.md` listing all fifteen CSV-classified files grouped by layer (model, mutations, types, migrations, factories, specs) with one-line non-obvious notes on each (e.g., the `room_id` -> `active_room_id` rename, the `current_song_id` -> `current_record_id` rename, the `user_rotation` `uuid[]` array shape, the deliberately omitted server-side fields in `RoomType`).
- Created `autopilot-support/index/features/rooms/patterns.md` covering the create-vs-activate lifecycle split, the layered team scoping (`teams` for single-room/activate vs `active_team` for list/create), the playback cursor tuple (`current_record_id`, `playing_until`, `queue_processing`, `waiting_songs`), the `idle!` / `playing_record!` atomic transitions, the `user_rotation` ordered-array semantics, and the `BroadcastTeamWorker` handoff on activation.
- Created `autopilot-support/index/features/rooms/boundaries.md` capturing extension points (new scalar fields, new state methods mirroring `idle!`, `user_rotation` as the DJ-order seam), do-not-build rules (no playlist logic in Room, no queue advancement in Room, no inline channel writes, no collapsing create+activate, no room-level ownership), and feature edges to playlist-management (`RoomPlaylistRecord`), queue-management (advancement worker/poller), real-time-playback (`NowPlayingChannel`), messages (`Message belongs_to :room`), teams, and user-authentication (`users.active_room_id`).

## Verify Result
- `test -s` on all three files: pass (no EMPTY output).
- CSV-basename presence check against `map.md`: pass — covered `room.rb` (model), `room_activate.rb`, `room_create.rb`, `room_type.rb`, `20190218193526_create_room.rb`, `20190218194925_add_room_to_user.rb`, `20190606125833_add_user_rotation_to_rooms.rb`, `20190928195833_update_room.rb`, `20191231013211_update_room_for_user.rb`, `room.rb` (factory), `room_spec.rb` (model), `room_activate_spec.rb`, `room_create_spec.rb`, `room_spec.rb` (query), `rooms_spec.rb`.
- Line-number leak grep (`:[0-9]+` excluding http): pass (no matches).

## Notes
- The `feature_classification.csv` lists two files named `room.rb` (the model and the factory) and two named `room_spec.rb` (the model spec and the single-room query spec). Both pairs are referenced under their distinct paths in `map.md`; the grep verify check accepts the shared basename as present in either case.
- Confirmed via `db/structure.sql` that `rooms` has `user_rotation uuid[] DEFAULT '{}'::uuid[]` and that `queue_processing` defaults to `false`; surfaced these in patterns without quoting the SQL.
- `Room#playing_record!` computes `playing_until` from `record.song.duration_in_seconds.seconds.from_now` at write time; flagged the lack of a recurring tick in patterns so future readers don't go looking for one.
- `RoomActivate` mutates the calling `User` (not the `Room`); called this out explicitly because the mutation name suggests room-side state change.
