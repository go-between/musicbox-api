# Resources

The API surface: a single GraphQL endpoint, a handful of ActionCable channels, and OAuth token issuance via Doorkeeper. There is no traditional REST controller layer — every read and every write flows through `POST /api/v1/graphql`.

## GraphQL endpoint

- `app/controllers/graphql_controller.rb` — the only application controller besides `ApplicationController`. Constructs `context = { current_user: current_user }` and calls `MusicboxApiSchema.execute`. Notable behaviors:
  - `NotAuthenticatedError` is caught and rendered as bare `head 401` (no JSON body).
  - In development only, `StandardError` is caught and rendered with full backtrace; in other envs it re-raises.
  - `ensure_hash` accepts `params[:variables]` as a JSON string, a Hash, `ActionController::Parameters`, or nil — pre-`6.1` shim that still lives here.
- `app/controllers/application_controller.rb` — inherits from `ActionController::API`. `current_user` is memoized from `doorkeeper_token.resource_owner_id`; no Devise session involvement at the controller layer.
- `app/graphql/musicbox_api_schema.rb` — schema entry, wires `Types::MutationType` and `Types::QueryType`. No subscription type — real-time delivery is ActionCable, not GraphQL subscriptions.
- `app/graphql/mutations.rb` and `app/graphql/types.rb` — empty module shells; the actual content lives in the per-class files.

## Mutations

All mutation classes inherit from `Mutations::BaseMutation` (`app/graphql/mutations/base_mutation.rb`), which:
- Overrides `ready?` to raise `NotAuthenticatedError` when `context[:current_user]` is blank — every mutation is logged-in-only by default.
- Mutations that must be callable while unauthenticated (account creation, password reset) override `ready?` to return `true` — see `invitation_accept.rb`, `password_reset_complete.rb`, `password_reset_initiate.rb`, `team_create.rb`.
- Provides `access_token_for(user_id)` which mints a non-expiring Doorkeeper access token with empty scopes. Used by mutations that complete an auth-establishing flow.
- Field registration happens in `app/graphql/types/mutation_type.rb` — the public mutation field name (snake_case) maps to the mutation class there. The class file basename matches the field name.

### Auth / account creation
- `team_create.rb` — bundled user-and-team bootstrap. Creates the team owner (or authenticates an existing user with the supplied password), creates the team, returns an access token. Public.
- `user_update.rb` — updates `User#name`. Uses a `UserUpdateInputObject` nested input class. Silently no-ops on blank attrs (returns an error).
- `user_password_update.rb` — verifies current password via `valid_password?` before delegating to Devise's `reset_password`.

### Invitations
- `invitation_create.rb` — `find_or_initialize_by` semantics for `(email, team)` so re-inviting is idempotent. Re-uses an existing token if already pending. Enqueues `EmailInvitationWorker`.
- `invitation_accept.rb` — public. Creates the user if not present, otherwise re-authenticates against the supplied password. Joins them to the inviting team and flips `invitation_state` to `:accepted`. Returns an access token.

### Password reset
- `password_reset_initiate.rb` — public. Silently returns `{ errors: [] }` when the email doesn't exist (no enumeration leak). Enqueues `EmailPasswordResetWorker` with the reset token.
- `password_reset_complete.rb` — public. Checks `reset_password_period_valid?` separately from token validity to give a distinct expired-token error. Returns an access token on success.

### Teams
- `team_activate.rb` — sets `current_user.active_team_id`. Broadcasts both old and new teams via `BroadcastTeamWorker` so presence updates on both sides.
- `team_create.rb` — see Auth above. The same mutation creates the user and the team in one step.

### Rooms
- `room_activate.rb` — sets `current_user.active_room_id` AND `active_team_id` from the room. Triggers `BroadcastTeamWorker`.
- `room_create.rb` — scoped to `current_user.active_team`. No team_id argument; the room inherits the user's active team.

### Playlist / queue
All four playlist mutations operate on the current user's `active_room`. They share a `BroadcastPlaylistWorker.perform_async(room_id)` fan-out.
- `room_playlist_records_add.rb` — adds songs to the end of the user's slot in the room. Lazily appends `current_user.id` to `room.user_rotation`. Also flips `room.waiting_songs = true`. Creates a `LibraryRecord` for each song if one doesn't already exist (so adding to queue implicitly saves to library).
- `room_playlist_records_reorder.rb` — full replace-set semantics for the user's waiting records: anything not in `ordered_records` gets destroyed. Uses a nested `OrderedPlaylistRecordInputObject`. Can also create new records when `room_playlist_record_id` is null.
- `room_playlist_record_delete.rb` — single-record delete; verifies ownership.
- `room_playlist_record_abandon.rb` — skip-current-song. Sets `room.playing_until = 1.second.ago` rather than mutating the record itself; the queue poller picks up the expired playback. Refuses unless the current record belongs to `current_user`.

### Messages
- `message_create.rb` — implicitly associates the message with `current_user.active_room.current_record` and that record's `song_id` (so chat is pinned-by-default to whatever is playing). Enqueues `BroadcastMessageWorker(room_id, message_id)`.
- `message_pin.rb` — toggles `Message#pinned`. Only the message author can pin. Enqueues `BroadcastPinnedMessagesWorker(room_id, song_id)`.

### Library
- `library_record_delete.rb` — soft scope: only deletes when the record belongs to `current_user`.

### Songs
- `song_create.rb` — `find_or_initialize_by(youtube_id:)`. For newly-created songs, calls `YoutubeClient.new(current_user).find(youtube_id)` and fills metadata (description, duration, name, thumbnail, channel, published_at, etc.). Also creates a `LibraryRecord` linking the song to `current_user` — when `from_user_id` is supplied, the record's `source` is set to `"saved_from_history"`.

### Tagging
- `tag_create.rb` — scoped to `current_user`; tag uniqueness is per-user.
- `tag_toggle.rb` — applies a single `tag_id` to a set of `add_ids` and removes from a set of `remove_ids` in one call. Uses `TagLibraryRecord.insert_all` and `delete_all` for bulk efficiency — no callbacks fire.

### Recommendations
- `recommendation_create.rb` — creates a `LibraryRecord` with `source: "pending_recommendation"` on the recipient, with `from_user_id = current_user.id`. Refuses if the recipient already has a LibraryRecord for the song.
- `recommendation_accept.rb` — flips `LibraryRecord#source` from `"pending_recommendation"` to `"accepted_recommendation"`. The recommendation model is reused as the library record once accepted.

### Listening
- `record_listen_create.rb` — only allowed when the supplied `record_id` matches `current_user.active_room.current_record_id`. Approval is clamped to `0..3`. Uses `find_or_create_by!` with a `RecordNotUnique` rescue to handle races. Broadcasts via `BroadcastRecordListensWorker(record_id)`.

## Query type

`app/graphql/types/query_type.rb` — one big class with all top-level queries. Notable patterns:

- Most resolvers call a local `confirm_current_user!` that raises `NotAuthenticatedError` unless `context[:current_user]` is present OR `context[:override_current_user]` is set. The override lets background workers (e.g. broadcast workers) execute queries on behalf of a user. The `invitation` and `unwound` queries deliberately skip this guard so they can be called by recipients of email links and (in unwound's case) by anonymous clients.
- `extras: [:lookahead]` is used heavily — resolvers manually compute `includes` from the lookahead selection set to avoid N+1. See `recommendations`, `record_listens`.
- Resolvers delegate to `Selectors::*` classes in `app/lib/selectors/` for non-trivial scoping (`Selectors::LibraryRecords`, `Selectors::Messages`, `Selectors::RoomPlaylistRecords`, `Selectors::SearchResults`). The selector receives the lookahead, scopes by `current_user`, then exposes chainable methods that mirror the GraphQL arguments.
- `pinned_messages` carries a comment about its dual-mode resolution (current_user vs. an explicit `room_id` from a broadcast worker context) — read it before changing.
- `room_playlist_for_user` is a current-user shortcut that bypasses `Selectors::RoomPlaylistRecords` and queries `RoomPlaylistRecord` directly with `.played` / `.waiting` scopes.
- `unwound` builds a `Unwound` value object (`app/lib/unwound.rb`) rather than scoping ActiveRecord — it's a stats aggregator.

## Base types and helpers

Located in `app/graphql/types/`. The `base_*` files are intentionally thin — they exist purely so domain types can inherit from project-local classes rather than from `GraphQL::Schema::*` directly:

- `base_object.rb`, `base_enum.rb`, `base_input_object.rb`, `base_interface.rb`, `base_scalar.rb`, `base_union.rb` — empty subclasses; extend these when adding cross-cutting behavior.
- `date_time_type.rb` — custom scalar. `coerce_input` parses with `Time.zone.parse`; `coerce_result` emits `utc.iso8601`. All datetime arguments use this rather than the built-in `GraphQL::Types::ISO8601DateTime`.
- `email_type.rb` — scalar that downcases on input. Use this for any email argument; it normalizes before the resolver runs so `find_by(email:)` works.
- `order_type.rb` — input object pairing `ordered_field` and `ordered_direction`. Used by `library_records` query.
- `ordered_field_type.rb` — scalar that `underscore`s on input and `camelize(:lower)`s on output, bridging GraphQL camelCase and Rails snake_case column names.
- `ordered_direction_type.rb` — scalar that downcases.
- `search_result_type.rb` — union of `Types::SongType` and `Types::YoutubeResultType`. The resolver inspects whether the value is a `Song` or an `OpenStruct` (YouTube results are wrapped in OpenStructs).

Domain types live as `*_type.rb` siblings (`song_type.rb`, `room_type.rb`, `user_type.rb`, etc.) — each one wraps a corresponding ActiveRecord model. See `app/graphql/types/`.

## ActionCable channels

Mounted at `/cable` (see `config/routes.rb`). All channels inherit from `ApplicationCable::Channel`.

- `app/channels/application_cable/connection.rb` — connection-level auth. `current_user` is resolved from `request.query_parameters[:token]` via `Doorkeeper::AccessToken.by_token` — the OAuth token is passed as a `?token=…` query string on the WebSocket URL. Unauthenticated connections are rejected. The connection is `identified_by :current_user`.
- `app/channels/application_cable/channel.rb` — base channel implementing `subscribed` as `stream_for current_user.active_room` (rejecting if no active room). This means `MessageChannel`, `NowPlayingChannel`, `PinnedMessagesChannel`, `RecordListensChannel`, `RoomPlaylistChannel` are all room-scoped by inheritance — they have no body of their own and exist purely for the broadcast namespace.

Per-channel notes:
- `message_channel.rb` — receives broadcasts from `BroadcastMessageWorker` (one per `MessageCreate`).
- `pinned_messages_channel.rb` — receives broadcasts from `BroadcastPinnedMessagesWorker` (one per `MessagePin`).
- `now_playing_channel.rb` — receives queue/playback advancement broadcasts (e.g. from `RoomQueuePoller`/`BroadcastPlaylistWorker`).
- `room_playlist_channel.rb` — receives broadcasts from `BroadcastPlaylistWorker` (playlist add/reorder/delete).
- `record_listens_channel.rb` — receives broadcasts from `BroadcastRecordListensWorker` (one per `RecordListenCreate`).
- `team_channel.rb` — overrides `subscribed` to stream for `current_user.active_team` instead of active_room. Receives broadcasts from `BroadcastTeamWorker` (team/room activation, presence). The only channel that is team-scoped instead of room-scoped.
- `users_channel.rb` — overrides `unsubscribed` to clear `current_user.active_room_id` when the WS disconnects, then enqueues `BroadcastTeamWorker(active_team_id)` so other clients see the user leave. This is the only "presence" mechanism — there is no separate Redis presence store.

## Routes

`config/routes.rb` is short. The whole file:

- `Sidekiq::Web` is mounted at `/workers`. There is no authentication wrapper — be aware before exposing the app to the open internet.
- `ActionCable.server` mounted at `/cable` — see channel auth above.
- `GraphiQL::Rails::Engine` mounted at `/graphiql`, pointing at `graphql_path: "/api/v1/graphql"`. `config/initializers/graphiql.rb` injects a `Bearer` header derived from a hard-coded local Doorkeeper token (see that initializer) so GraphiQL works against the auth-guarded schema.
- `POST /api/v1/graphql` → `graphql#execute`.
- `use_doorkeeper` (Doorkeeper's `/oauth/token`, `/oauth/applications`, etc.) mounted under `/api/v1/`. The clients exchange Devise email/password for an access token via the standard password grant here.
- **Devise is configured (`config/initializers/devise.rb`) but NOT routed.** There is no `devise_for :users`. Devise's role is purely model-level (`User` includes `:database_authenticatable`, etc.) and is exercised through the GraphQL mutations (`TeamCreate`, `InvitationAccept`, `PasswordReset*`) and through Doorkeeper's password grant. Adding a Devise route would conflict with that flow.

## Authorization model

Three layers, each independent:

1. **GraphQL resolver layer.** `context[:current_user]` is set in `GraphqlController#execute` from `current_user` (which reads `doorkeeper_token.resource_owner_id`). Mutations check via `Mutations::BaseMutation#ready?`; queries check via `confirm_current_user!`. Public mutations override `ready?`. Both layers raise `NotAuthenticatedError` (`app/lib/not_authenticated_error.rb`), which the controller catches and converts to HTTP 401. There is no `Pundit`/`CanCan` style policy layer — finer-grained authorization (e.g. "only the message author can pin") is enforced inline in resolvers via `find_by(user: current_user, …)`.
2. **OAuth layer (Doorkeeper).** `app/controllers/application_controller.rb#current_user` reads `doorkeeper_token` and resolves the resource owner. All tokens minted from in-app flows (`access_token_for` in `BaseMutation`) are non-expiring with empty scopes; tokens minted via the standard password grant come through `use_doorkeeper`'s `/oauth/token` route.
3. **ActionCable layer.** `ApplicationCable::Connection` does its own token verification from the WebSocket query string — it does not share `current_user` with the HTTP controller. Channels add a second authorization check in `subscribed` (reject if `active_room` / `active_team` is blank).

There is no admin role, no scope system, and no rate-limiting middleware in the codebase. Tokens are bearer credentials with full access to the resource owner's data.
