# User Authentication & Management — Patterns

Non-obvious conventions used across this feature. The "what" lives in the code; this file is the "why" and "watch out for".

## Devise modules in use (and the ones missing)

`User` declares only `:database_authenticatable, :recoverable, :validatable`. Notable omissions: no `:registerable` (sign-up is not a Devise route — users are created either through invitation acceptance in `features/user-invitations/` or by tests/seeds), no `:rememberable` (the `remember_created_at` column was removed by `db/migrate/20200423152618_remove_remember_at_from_user.rb`), no `:trackable`, no `:confirmable`, no `:lockable`, no `:timeoutable`. The commented-out schema blocks in `db/migrate/20190329051901_add_devise_to_users.rb` document this intentionally.

## OAuth: password grant only, tokens never expire

`config/initializers/doorkeeper.rb` enables exactly one grant flow: `grant_flows %w[password]` (Resource Owner Password Credentials). Clients POST `username` + `password` to the Doorkeeper-mounted `/api/v1/oauth/token` endpoint (see `use_doorkeeper` in `config/routes.rb`) and receive a bearer token. `access_token_expires_in nil` — tokens never expire. There is no refresh-token logic in this app; nothing calls `use_refresh_token`. Sign-out, on the client, just means discarding the token.

## How Devise and Doorkeeper hand off

`resource_owner_from_credentials` in `config/initializers/doorkeeper.rb` calls `User.find_for_database_authentication(email: params[:username])` (a Devise method) and then `user.valid_for_authentication? { user.valid_password?(params[:password]) }`. The `valid_for_authentication?` wrapper is what runs Devise's `active_for_authentication?` hook chain — if a future module (or override) returns false from `active_for_authentication?`, token issuance silently fails (returns nil = invalid credentials response). This is the canonical extension point to lock accounts without adding `:lockable`.

## `current_user` resolution: three separate code paths

1. **HTTP / GraphQL** — `app/controllers/application_controller.rb#current_user` reads `doorkeeper_token` (set by Doorkeeper from the `Authorization: Bearer …` header) and finds the user by `resource_owner_id`. `GraphqlController#execute` stuffs that into `context: { current_user: … }` before invoking the schema. **It does not raise if missing.**
2. **GraphQL inside the schema** — auth is enforced lazily, at field resolution, not at the controller:
   - Mutations: `Mutations::BaseMutation#prepare_response` raises `NotAuthenticatedError` when `context[:current_user].blank?`. Every mutation inherits this.
   - Queries: `QueryType#confirm_current_user!` raises `NotAuthenticatedError` unless `current_user` is present. Every public query field calls `confirm_current_user!` explicitly as its first line — there is no global `before_action`.
3. **ActionCable** — `app/channels/application_cable/connection.rb` reads the token from `request.query_parameters[:token]` (because WebSocket clients can't set `Authorization` headers in browsers) and calls `reject_unauthorized_connection` when the lookup fails. The token in the URL ends up in server logs — keep that in mind when debugging.

These three paths share `Doorkeeper::AccessToken` as the storage but do not share a resolver. Don't try to DRY them.

## The `override_current_user` context flag

Broadcast workers (including `BroadcastUsersWorker`) re-execute the schema server-side with `context: { override_current_user: true }`. `QueryType#confirm_current_user!` checks this flag and returns early; mutations inherit `BaseMutation` and **do not** honor the flag — so workers may only run queries, not mutations. If you add a new public query field, copy the `confirm_current_user!` line in; do not assume it's inherited.

## `NotAuthenticatedError` lifecycle

Defined in `app/lib/not_authenticated_error.rb` as a bare `StandardError`. Raised by `BaseMutation` and `QueryType` (above). Rescued in `GraphqlController#execute` and rendered as `status: 401` with no body — clients pattern-match on the HTTP status, not on a GraphQL error payload. This is why the response shape for "not logged in" and a GraphQL parse error look completely different.

## Password update goes through `reset_password`, not `update`

`Mutations::UserPasswordUpdate` calls Devise's `reset_password(new, new)` — note that this is *not* the recoverable token-based reset; when called directly it just runs the password-strength validations and saves. This is why the error string for a weak password is `"Insecure password"` (the boolean return of `reset_password`) rather than the model's validation messages. If you need to surface real Devise errors, you must change to `update(password: …, password_confirmation: …)` and read `current_user.errors`.

## `UserUpdate` is whitelist-only

`Mutations::UserUpdate#update_with` rebuilds a hash from scratch, copying only fields it explicitly enumerates. Adding a new updatable field requires both adding the `argument` to `UserUpdateInputObject` and adding a line inside `update_with`. There is no automatic mass-assignment.

## Email uniqueness and casing

`config/initializers/devise.rb` sets `case_insensitive_keys = [:email]` and `strip_whitespace_keys = [:email]`. Devise downcases and strips the column on every write — so the DB row will not contain the input verbatim. `users.email` has a unique index added by `db/migrate/20190329051901_add_devise_to_users.rb`; uniqueness is enforced both by `validatable` and by Postgres.

## bcrypt cost is environment-specific

`config.stretches = Rails.env.test? ? 1 : 11`. The factory password `"hunter2"` only encrypts in milliseconds because of this — do not assume production hashing speed from test runs.

## `users` table is UUID, but the migration history is a graveyard

The current schema came from three migrations in sequence — create with no Devise, drop, then recreate with Devise on a `uuid` id. The Doorkeeper tables were similarly recreated to switch `resource_owner_id` from integer to `uuid`. Treat `db/migrate/20190329051721_*` and `db/migrate/20190329055527_*` (the two `drop_*` migrations) as historical artifacts — never roll back past them, and read `db/structure.sql` for the live shape.

## `UsersChannel#unsubscribed` is the "user left" signal

There is no explicit "leave room" mutation. The browser disconnecting from the channel is the trigger: `UsersChannel#unsubscribed` clears `current_user.active_room` and fires `BroadcastTeamWorker`. If you add a server-side path to forcibly remove a user from a room, replicate this two-step (clear `active_room`, broadcast) rather than calling `unsubscribed` directly.

## `start_password_reset!` exists so `features/password-reset/` can call `set_reset_password_token`

`Devise::Recoverable#set_reset_password_token` is `protected`. `User#start_password_reset!` exists only to expose it to external callers (the password-reset mutation). Don't inline the protected method elsewhere — go through `start_password_reset!` and add behavior to that single method if needed.
