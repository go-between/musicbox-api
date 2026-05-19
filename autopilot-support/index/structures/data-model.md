# Data Model

Authoritative schema lives in `db/structure.sql` (the project uses structure.sql, not schema.rb — see commit `8a9a086`). All tables use `uuid` primary keys (`gen_random_uuid()`). This doc captures the non-obvious shape of the domain; consult the model files in `app/models/` for behavior and `db/structure.sql` for column-level truth.

## Domain in one paragraph

Users belong to Teams (many-to-many via `teams_users`). Each Team has many Rooms. A Room is the listening session: it plays through an ordered queue of `RoomPlaylistRecord` rows (each pointing at a `Song`). As a record plays, `RecordListen` rows capture each listener's reaction. Users build personal libraries of songs via `LibraryRecord` (with optional recommendation flow between users), and tag those library entries with personal `Tag`s through the `tags_library_records` join. Invitations onboard new users into a Team.

## Models

### `User` — `app/models/user.rb`
- Devise: `database_authenticatable`, `recoverable`, `validatable` (so `users.email`, `encrypted_password`, `reset_password_token` are Devise-owned).
- Two "active session" pointers on the user row itself: `active_room_id` and `active_team_id` (both optional `belongs_to` back to `Room`/`Team`). These represent which room/team the user is currently focused on — surprising because they live on `users`, not on a session table.
- `has_many :library_records` is **scoped to exclude `pending_recommendation` source** (with explicit NULL handling because Postgres `!=` excludes NULLs). Anyone querying `user.songs` or `user.library_records` is implicitly filtering out pending recommendations — use `LibraryRecord.where(user: user)` directly to see them.
- `start_password_reset!` exposes Devise's protected `set_reset_password_token` for explicit invocation.
- Hot lookups: unique index on `users.email`, unique index on `reset_password_token`, index on `active_room_id` (see `db/structure.sql`).

### `Team` — `app/models/team.rb`
- Required `owner` (`belongs_to :owner, class_name: "User"` via `owner_id`) — every team has exactly one owning user. No validation in the model; relies on DB-level association.
- `has_many :rooms`, `has_many :users, through: :team_users`.

### `TeamUser` — `app/models/team_user.rb`
- Join table for `Team` <-> `User`. Note the explicit `self.table_name = "teams_users"` (Rails would default to `team_users`; the DB uses the pluralized form `teams_users`).
- Indexes on both `team_id` and `user_id` in `db/structure.sql`.

### `Room` — `app/models/room.rb`
- Belongs to a `Team`. Hosts the playback state machine:
  - `current_record` (`belongs_to :current_record, class_name: "RoomPlaylistRecord"`) — the song currently playing.
  - `current_song` (`has_one :current_song, through: :current_record, source: :song`) — convenience shortcut.
  - `playing_until` — timestamp when the current song ends (indexed; see `index_rooms_on_playing_until` — this is the hot path for the playback worker that finds rooms whose songs have finished).
  - `queue_processing` (default `false`) — guard flag while the queue is being advanced.
  - `waiting_songs` — boolean signaling there are no queued songs.
  - `user_rotation` — `uuid[]` column on `rooms`. Drives DJ-rotation order for queue picking; surprising because it's a Postgres array, not a join table.
- `Room#idle!` clears `current_record`, `playing_until`, `queue_processing`, and `waiting_songs` (the "room is empty / nothing playing" state).
- `Room#playing_record!(record)` sets `current_record`, computes `playing_until` from `record.song.duration_in_seconds.seconds.from_now`, and clears `queue_processing`.
- `has_many :users, foreign_key: :active_room_id` — the inverse of `User#active_room`; lists users currently focused on this room.

### `RoomPlaylistRecord` — `app/models/room_playlist_record.rb`
- The queue row: one `Song` queued by one `User` in one `Room`. Has an `"order"` integer column (quoted because `order` is a SQL reserved word).
- `enum :play_state, { played: "played", waiting: "waiting" }` — string-backed enum. Drives the "what's still in the queue vs what's been played" split. Indexed on `play_state` and `played_at` (timestamps when the record actually played). Also indexed on `room_id`, `song_id`, `user_id` — heavily-queried join target.
- `has_many :record_listens`.

### `RecordListen` — `app/models/record_listen.rb`
- One row per (record, song, user) — represents a user's reaction to a specific play of a specific song in a queue. Has an `approval` integer column (default `0`) which is **not** modeled as a Rails enum but is treated as one upstream (likely values like -1/0/1 for skip/neutral/up; check resolvers).
- **Unique index** `unique_record_listens` on `(room_playlist_record_id, song_id, user_id)` — at most one listen per user per playback (see `db/structure.sql`). Also separately indexed on `room_playlist_record_id` and `song_id`.

### `Song` — `app/models/song.rb`
- Validates `youtube_id` presence (songs are YouTube videos).
- `youtube_tags` is a `varchar[]` array column on `songs`.
- **Full-text + fuzzy search.** `songs.text_search` is a generated `tsvector` column (`GENERATED ALWAYS AS … STORED`) that weights `name` and `channel_title` as A, `youtube_tags` (via `immutable_array_to_string`) as B, and `description` as C. There's a custom IMMUTABLE function `public.immutable_array_to_string` defined in `db/structure.sql` to make this work in a generated column.
- Three search scopes:
  - `Song.fulltext_search(q)` — pure `tsvector @@ plainto_tsquery` ranked by `ts_rank`.
  - `Song.fuzzy_search(q)` — pg_trgm `<%` operator over `name + channel_title + youtube_tags`, ordered by `<<->` word-distance.
  - `Song.search(q)` — 3-tier combined query: FTS, then trigram fuzzy, then `ILIKE` substring, with a `CASE` ordering that puts FTS matches first.
- Indexes that imply hot search paths: `index_songs_on_text_search` (GIN on the tsvector), `index_songs_on_searchable_content_trgm` (GiST trigram on the combined expression), `index_songs_on_name` (GIN trgm), plus btree indexes on `channel_id`, `duration_in_seconds`, `published_at`, `youtube_id`, and a separate `song_name_order_index` on `name` for ordering.
- `has_many :users, through: :library_records` — note this is **unscoped** (it ignores the `pending_recommendation` filter that `User#library_records` applies).

### `LibraryRecord` — `app/models/library_record.rb`
- The user's saved library: one `Song` saved by one `User`, optionally `from_user` (the recommender).
- `enum :source, { saved_from_history: "saved_from_history", pending_recommendation: "pending_recommendation", accepted_recommendation: "accepted_recommendation" }` — string-backed. Drives the recommendation flow: a `from_user` sends a song to another user; it starts as `pending_recommendation` (hidden from `User#library_records`) until the recipient accepts it (`accepted_recommendation`). Songs the user saves themselves are `saved_from_history`.
- Indexed on `created_at`, `song_id`, `user_id`, and `source` (`db/structure.sql`).
- `has_many :tags, through: :tag_library_records`.

### `Tag` — `app/models/tag.rb`
- Per-user tag (belongs_to `User` — tags are private to each user, not global). Validates `name` presence. Indexed on `user_id`.

### `TagLibraryRecord` — `app/models/tag_library_record.rb`
- Join between `Tag` and `LibraryRecord`. Explicit `self.table_name = "tags_library_records"` (Rails would otherwise look for `tag_library_records`).
- **Unique composite index** on `(tag_id, library_record_id)` prevents duplicate tagging. Also individually indexed on each FK.

### `Message` — `app/models/message.rb`
- Chat-style messages tied to a `Room` (required) and `User` (required), optionally to a `RoomPlaylistRecord` and/or `Song`. Has a `pinned` boolean (default `false`).
- Indexed on `created_at` and `room_id` (hot path: paginated room chat history).

### `Invitation` — `app/models/invitation.rb`
- Belongs to `Team` and `inviting_user` (`User` via `invited_by_id`).
- Surprising: `invited_user` is a `belongs_to` against `User` keyed by **email** (`foreign_key: :email, primary_key: :email`) — so the association resolves the invited user lazily once they exist (or stays `nil` until signup).
- `Invitation.token` class method generates a `SecureRandom.uuid` (note: the `token` column is `uuid` type). The model does **not** auto-assign — callers must set the token explicitly.
- `enum :invitation_state, { pending: "pending", accepted: "accepted" }` — string-backed.
- Indexed on `token` (lookup-by-link path).

## Notes and gotchas

- **No `app/models/concerns/`** — directory does not exist; no shared model concerns.
- **All tables use `uuid` PKs.** Foreign keys are `uuid` columns; no integer IDs anywhere.
- **Devise + Doorkeeper.** Devise owns user auth columns on `users`; Doorkeeper owns `oauth_access_grants`, `oauth_access_tokens`, `oauth_applications` (no Rails models in `app/models/` for these — they come from the gems). Token uniqueness enforced at DB level (`db/structure.sql`).
- **Two join tables use legacy plural-plural naming** (`teams_users`, `tags_library_records`) and the corresponding Rails models override `self.table_name` accordingly.
- **`Room#user_rotation`** as a Postgres `uuid[]` is unusual — anyone modifying queue/rotation logic should expect array semantics, not a join table.
- **`pending_recommendation` is invisible by default.** The default-scope-like behavior on `User#library_records` means almost any `current_user.library_records` or `current_user.songs` call silently filters them out. Use `LibraryRecord` directly when querying recommendations.
- **Generated tsvector column.** `songs.text_search` is maintained by Postgres — you cannot write to it. Updates to `name`/`channel_title`/`youtube_tags`/`description` automatically refresh it. The custom `immutable_array_to_string` function in `db/structure.sql` is required for the generated expression to be IMMUTABLE.
