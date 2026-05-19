# Song Library — Map

## Model
- `app/models/song.rb` — `Song` AR model. Validates `youtube_id` presence. Owns three search scopes (`fulltext_search`, `fuzzy_search`, `search`) built on the `text_search` tsvector generated column plus a pg_trgm fallback. Has many `library_records` and (through) `users`.

## GraphQL
- `app/graphql/mutations/song_create.rb` — `Mutations::SongCreate`. `find_or_initialize_by(youtube_id:)`, fetches metadata via `YoutubeClient` only on first insert, then attaches a `LibraryRecord` for the caller. Optional `from_user_id` argument stamps the record as `source: "saved_from_history"`.
- `app/graphql/types/song_type.rb` — `Types::SongType`. Exposes YouTube-sourced metadata fields and the back-reference to `library_records`. `youtube_id` and `licensed` are non-null; most metadata is nullable because it is populated asynchronously from YouTube.

## Migrations
- `db/migrate/20190218202341_create_song.rb` — Initial table (UUID id, `name`, `url`, `room_id`). The `url` and `room_id` columns no longer exist (see follow-up migrations).
- `db/migrate/20190305135026_add_duration_in_seconds_to_songs.rb` — Adds `duration_in_seconds` (populated from YouTube metadata at create time, not user input).
- `db/migrate/20190322022735_remove_room_from_song.rb` — Drops `room_id`; songs are global, not per-room.
- `db/migrate/20190322030217_add_index_to_songs.rb` — Indexes `youtube_id` (non-unique). Uniqueness is enforced by the `find_or_initialize_by` pattern in `SongCreate`, not by a DB constraint.
- `db/migrate/20190326121153_update_song_table.rb` — Replaces `url` with `description`.
- `db/migrate/20190407020627_add_song_data_to_room.rb` — Adds `current_song_id` / `current_song_start` to `rooms` (caller-side, not on songs).
- `db/migrate/20200226234654_add_gin_index_to_song_name.rb` — Adds the pg_trgm GIN index on `songs.name` used by fuzzy/ILIKE search.
- `db/migrate/20200415022511_add_youtube_details_to_songs.rb` — Adds `thumbnail_url`, `license`, `licensed`, `youtube_tags` (string array, default `[]`).

## Specs
- `spec/factories/song.rb` — Minimal `:song` factory; only `name` and `youtube_id` are seeded. YouTube-derived fields are left nil unless tests set them explicitly.
- `spec/models/song_spec.rb` — Relationship coverage plus the `.search` contract: name/prefix/channel/description/tag matching, ranking by ts_rank, fuzzy fallback for substring queries, nil-safety.
- `spec/mutations/song_create_spec.rb` — Documents the create-vs-reattach behavior, the `YoutubeClient` stubbing convention, and the `from_user_id` source-stamping path. Also pins the empty-`youtube_id` error string.
