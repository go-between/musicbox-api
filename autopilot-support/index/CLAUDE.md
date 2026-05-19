# musicbox-api Index

This index is the entry point for navigating the musicbox-api codebase. It is **not** a substitute for reading the code — it is a map that tells you *where to look* and *what is non-obvious*.

musicbox-api is a Rails GraphQL API powering a real-time, social music listening application. Users join teams, gather in rooms, build collaborative playlists from YouTube-backed songs, chat, and watch synchronized playback. The backend is GraphQL-only over a single REST endpoint, with ActionCable channels broadcasting room state to connected clients and Sidekiq workers handling email and broadcast fan-out.

## Index Rules

Every file in this index obeys these rules. Future writers must too.

1. **Point to files, never duplicate code.** Reference paths like `app/models/room.rb`. Never paste code blocks or function bodies into the index.
2. **No line numbers.** Files churn; line numbers rot. Reference symbols by name (`Room#activate!`), not location.
3. **Only non-obvious information.** If a reader can learn it in 30 seconds by reading the file, don't write it here. The index records *why*, *where to look*, and *what's surprising* — not *what the code says*.
4. **Manifest is the entry point.** This file lists every structure and feature file. Anything added to the index must be listed here.
5. **Three-file feature convention.** Each `features/{slug}/` directory contains exactly three files:
   - `map.md` — what files comprise this feature and what each does (one line per file, points to path)
   - `patterns.md` — non-obvious conventions, idioms, and abstractions used by this feature
   - `boundaries.md` — extension points, "do not build" items, and where this feature ends / another begins
6. **`feature_classification.csv` is the source of truth for feature scope.** Filter its rows by the `Feature` column to find which files belong to a feature.

## Structures

Cross-cutting views of the codebase, organized by concern rather than by feature.

- [structures/modules.md](structures/modules.md) — How non-MVC code is organized: `app/lib/` plain Ruby services and the `Selectors` namespace, `app/workers/` Sidekiq jobs grouped into `broadcast_*` / `email_*` / standalone, and the single `room:poll_queue` rake task.
- [structures/data-model.md](structures/data-model.md) — Models, relationships, and surprising fields. UUID PKs throughout; points at `db/structure.sql` (authoritative since commit `8a9a086`) for column-level truth.
- [structures/resources.md](structures/resources.md) — The single `POST /api/v1/graphql` endpoint, 23 mutations grouped by domain, the `QueryType` resolver, 9 ActionCable channels (auth via Doorkeeper token in WebSocket query string), and the three-layer authorization model.
- [structures/infrastructure.md](structures/infrastructure.md) — Sidekiq, ActionCable, Redis, Postgres (+ `pgcrypto` + `pg_trgm` extensions), Devise + Doorkeeper (password-grant only, non-expiring tokens), Airbrake, Docker, Render, nginx, Passenger, and Clockwork. Operational details defer to `README.md` and `COSTS.md`.
- [structures/testing.md](structures/testing.md) — RSpec suite mirrored to the GraphQL-first architecture (no controller/system/view specs). Auth in tests goes through real Doorkeeper tokens via `spec/support/auth_helper.rb`; email workers share `spec/workers/email_worker_shared_examples.rb`; `Sidekiq::Testing.inline!` is per-spec opt-in.

## Features

Each feature directory holds three files (`map.md`, `patterns.md`, `boundaries.md`). The slug below maps to the CSV `Feature` label, with the highest-value non-obvious detail surfaced.

- [features/user-authentication/](features/user-authentication/) — *User Authentication & Management*. Devise + Doorkeeper (password grant only, non-expiring tokens). `current_user` resolved through three separate paths (controller, GraphQL context, ActionCable connection); `User#start_password_reset!` exists to expose Devise's protected token-setter to the password-reset feature.
- [features/user-invitations/](features/user-invitations/) — *User Invitation System*. Token-based invite flow with direct-HTTP Mailgun delivery; `invited_user` association is email-keyed (works before user exists). `Invitation.token` is a class method; idempotent `find_or_initialize_by(email, team)` is the seam.
- [features/password-reset/](features/password-reset/) — *Password Reset System*. Devise-managed `reset_password_token` + `reset_password_sent_at`; initiate returns empty errors on unknown email (no enumeration); complete returns a Doorkeeper access token on success.
- [features/teams/](features/teams/) — *Team Collaboration*. `Team#owner` is an FK on `teams`, not a join. `team_users` membership pinned to the legacy `teams_users` plural-plural table name; `User#active_team_id` carries current-team context.
- [features/rooms/](features/rooms/) — *Room Management*. Users belong to a room via `users.active_room_id` (not `room_id`). `Room#idle!` and `Room#playing_record!` are the atomic state transitions; `user_rotation` is a `uuid[]` array column for round-robin DJ order.
- [features/playlist-management/](features/playlist-management/) — *Playlist Management*. `RoomPlaylistRecord` is a Room×Song×User join with `play_state` enum (`waiting`/`played`); `RoomPlaylistGenerator` interleaves by `Room#user_rotation` under `room.with_lock`. Add is append; reorder is destructive replace.
- [features/queue-management/](features/queue-management/) — *Queue Management*. Clockwork (1Hz) polls via `RoomQueuePoller`, which flips qualifying rooms to `queue_processing: true` with `update_all` before enqueueing `QueueManagementWorker` — the flip is the idempotency lock.
- [features/real-time-playback/](features/real-time-playback/) — *Real-time Music Playback*. A no-body `NowPlayingChannel` plus one worker that re-runs a GraphQL query and pushes the result. Clients sync via `playedAt + durationInSeconds`; no heartbeat, no server-driven seek.
- [features/messages/](features/messages/) — *Message & Chat System*. Pin is the `pinned` boolean column on `Message`, not a separate model. Two channels (`MessageChannel`, `PinnedMessagesChannel`) because pinned needs its own stream; both broadcast via GraphQL-shaped payloads.
- [features/music-library/](features/music-library/) — *User Music Library*. `LibraryRecord` is the user↔song join. `source` enum (`saved_from_history`, `pending_recommendation`, `accepted_recommendation`) carries provenance; `User#library_records` filters out pending recommendations via Arel. Deletion is destructive.
- [features/songs/](features/songs/) — *Song Library*. `youtube_id` uniqueness is app-enforced (no DB constraint). `SongCreate` hydrates YouTube metadata only on first insert. `Song.search` is a 3-tier OR (tsvector + pg_trgm fuzzy + ILIKE fallback) — but see the search feature for what's actually wired.
- [features/listening-history/](features/listening-history/) — *Music Listening History*. The `unique_record_listens` index dedups per `(room_playlist_record, song, user)`; `approval` is mutated in place. `RecordListenCreate` gates on `active_room.current_record_id` as a security boundary.
- [features/music-statistics/](features/music-statistics/) — *Music Statistics*. `Unwound` (live GraphQL resolver) and `MusicboxUnwound` (frozen console script) are parallel implementations, not a wrapper pair. Plays come from `RoomPlaylistRecord`; approvals come from `RecordListen`.
- [features/tagging/](features/tagging/) — *Music Tagging*. Tags are user-scoped (not global/team). `TagLibraryRecord` joins to `LibraryRecord`, not `Song`; table name pinned to legacy `tags_library_records` plural-plural; uniqueness enforced at the DB index with `insert_all`/`delete_all` skipping callbacks.
- [features/recommendations/](features/recommendations/) — *Music Recommendation*. No `Recommendation` model — recommendations are `LibraryRecord` rows in `pending_recommendation`/`accepted_recommendation` states. The `recommendations` GraphQL query has two asymmetric modes (inbox vs. song-scoped outbox).
- [features/search/](features/search/) — *Search Functionality*. The wired GraphQL `search` path uses a plain ILIKE on `songs.name` via `Selectors::SearchResults#from_all_songs` — `Song`'s 3-tier ranked search is implemented but not yet invoked through GraphQL. Flagged as the obvious extension point.
- [features/youtube/](features/youtube/) — *YouTube Integration*. `YoutubeClient` is raw `Net::HTTP` with no retries, no error handling, no Airbrake integration despite the initializer being configured. Constructor takes a `user` arg it never uses — kept for future per-user OAuth/quota. Hydration is single-shot.

## How to extend this index

- When you add a new structure file, link it under **Structures** above with a one-line summary derived from its H1 + intro.
- When you add a new feature, create `features/{slug}/{map,patterns,boundaries}.md` and link the directory under **Features** with the CSV `Feature` label and the highest-value non-obvious detail.
- When a feature's scope shifts, update both the `boundaries.md` of the affected features and the one-line summary here.
- Run the integrity checks before merging an index change: every linked file must exist; every produced `.md` must be referenced; no `\.rb:N` / `\.sql:N` patterns; no ```ruby / ```rb fences.
