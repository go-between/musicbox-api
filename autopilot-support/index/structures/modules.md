# Modules

How non-MVC code is organized: `app/lib/` for plain Ruby service objects and selectors, `app/workers/` for Sidekiq jobs, and `lib/tasks/` for rake.

## `app/lib` organization

Service objects live as top-level classes (not namespaced) directly under `app/lib/`. Two flavors:

- **Domain logic services**: `app/lib/room_playlist_generator.rb` (`RoomPlaylistGenerator`) — interleaves user playlists by rotating through `room.user_rotation`. Called by `app/workers/queue_management_worker.rb` and `app/lib/selectors/room_playlist_records.rb`. `app/lib/room_queue_poller.rb` (`RoomQueuePoller`) — polls for rooms that need their queue advanced (newly enqueued or playback expired) and dispatches `QueueManagementWorker`. Run continuously by the `room:poll_queue` rake task.
- **External clients**: `app/lib/youtube_client.rb` (`YoutubeClient`) wraps the YouTube Data v3 API via raw `Net::HTTP` (no gem); read `ENV["YOUTUBE_KEY"]`. Only caller is `app/graphql/mutations/song_create.rb` and `app/lib/selectors/search_results.rb`.
- **Reporting one-offs**: `app/lib/musicbox_unwound.rb` (`MusicboxUnwound`) is a console-only report that `puts` Terminal::Table output and hardcodes the team name `"Plug Dot DJ Expats"` — not wired into GraphQL. `app/lib/unwound.rb` (`Unwound`) is the GraphQL-facing version returning structured hashes; invoked from `QueryType#unwound` in `app/graphql/types/query_type.rb`. Despite the similar names these are separate codepaths.
- **Errors**: `app/lib/not_authenticated_error.rb` defines `NotAuthenticatedError`, raised by `app/graphql/mutations/base_mutation.rb` and `QueryType` and rescued in `app/controllers/graphql_controller.rb` to convert auth failures into a 401-style GraphQL response.

## Selectors pattern

`app/lib/selectors.rb` only declares the empty `Selectors` module — it is just a namespace anchor. The real work lives in `app/lib/selectors/*.rb`, each a class that wraps a GraphQL `lookahead:` and builds an ActiveRecord relation with the right `includes` to avoid N+1. Pattern: instantiate with `lookahead:` (and other context like `user:`), chain scoping methods that return `self` (e.g., `for_user`, `with_query`, `with_tags`, `in_date_range`), then call a terminal method that returns the relation.

Invoked exclusively from `app/graphql/types/query_type.rb`: `Selectors::LibraryRecords` (library query), `Selectors::Messages` (messages and pinnedMessages — same selector class, two callers), `Selectors::RoomPlaylistRecords` (roomPlaylist field; delegates to `RoomPlaylistGenerator` for the non-historical case), and `Selectors::SearchResults` (falls back from local `Song` search to `YoutubeClient` when local has no hits). `LibraryRecords` is the most complex — it carries custom postgres FTS + trigram fuzzy ranking SQL in `apply_song_search_order`.

## Concerns

There are no concerns. `app/models/concerns/.keep` and `app/controllers/concerns/.keep` are placeholders left by Rails generators; `app/concerns/` does not exist. All model/controller logic lives in the class file directly.

## Workers

All workers are Sidekiq jobs in `app/workers/` and each declares its own named queue via `sidekiq_options queue:`. Three groupings:

- **`broadcast_*` family**: each maps to one ActionCable channel and re-executes a hardcoded GraphQL query through `MusicboxApiSchema.execute` with `context: { override_current_user: true }` (skips auth). Pairings — `broadcast_message_worker.rb` -> `MessageChannel`, `broadcast_now_playing_worker.rb` -> `NowPlayingChannel`, `broadcast_pinned_messages_worker.rb` -> `PinnedMessagesChannel`, `broadcast_playlist_worker.rb` -> `RoomPlaylistChannel`, `broadcast_record_listens_worker.rb` -> `RecordListensChannel`, `broadcast_team_worker.rb` -> `TeamChannel`, `broadcast_users_worker.rb` -> `UsersChannel`. The GraphQL query strings are inlined in each worker's private `query` method.
- **`email_*` family**: bypasses ActionMailer entirely; both `email_invitation_worker.rb` and `email_password_reset_worker.rb` POST directly to the Mailgun HTTP API at `api.mailgun.net/v3/mg.musicbox.fm/messages` using `Net::HTTP` and an `ENV["MAILGUN_KEY"]` basic-auth credential. Templates (`invitation`, `password-reset`) are stored in Mailgun, not the repo. Each defines its own `DeliveryError`.
- **Standalone**: `queue_management_worker.rb` (`QueueManagementWorker`) is the central playback advancer — runs `room.with_lock`, calls `RoomPlaylistGenerator` to pick the next record, updates room state, then fans out to `BroadcastTeamWorker`, `BroadcastNowPlayingWorker`, and `BroadcastPlaylistWorker`. Enqueued by `RoomQueuePoller#enqueue_for`.

## `lib/tasks`

Only one rake task exists: `lib/tasks/room.rake` defines `room:poll_queue`, an infinite loop that runs `RoomQueuePoller#poll!` every 0.1s. This is the entry point for the background poller process (intended to run as a long-lived process, not a cron). The `lib/tasks/.keep` file is a leftover Rails generator placeholder.
