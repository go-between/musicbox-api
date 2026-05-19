# User Authentication & Management — Map

Every file in scope for this feature, per `feature_classification.csv` (`Feature == "User Authentication & Management"`). One line per file, pointing at its role.

## Model

- `app/models/user.rb` — `User` is the Devise resource (`:database_authenticatable, :recoverable, :validatable`) and the OAuth resource owner; exposes `start_password_reset!` as the public alias for Devise's protected `set_reset_password_token`. All other associations (`active_room`, `active_team`, `library_records`, `team_users`/`teams`, `tags`, `room_playlist_records`) are owned by other features but hang off this class.

## GraphQL — mutations

- `app/graphql/mutations/user_password_update.rb` — `Mutations::UserPasswordUpdate` verifies the old password via `valid_password?` then calls Devise's `reset_password(new, new)` to set the new one; returns `errors: ["Invalid password"]` or `errors: ["Insecure password"]`. No `user` field returned.
- `app/graphql/mutations/user_update.rb` — `Mutations::UserUpdate` accepts a `UserUpdateInputObject` and only updates `:name` today; uses the internal `update_with` whitelist pattern so new fields require explicit handling (no mass-assignment).

## GraphQL — types

- `app/graphql/types/user_type.rb` — `Types::UserType` (graphql_name `"User"`) — public user surface: `id`, `email`, `name`, `active_room`, `active_team`, `teams`. Password/Devise internals are deliberately not exposed.

## Channels

- `app/channels/users_channel.rb` — `UsersChannel` — clears `active_room` on `unsubscribed` (browser close / network drop) and enqueues `BroadcastTeamWorker` so other clients see the user leave the room.

## Workers

- `app/workers/broadcast_users_worker.rb` — `BroadcastUsersWorker` (queue `broadcast_users`) — re-runs a hardcoded `room.users { id name email }` query through `MusicboxApiSchema.execute` with `context: { override_current_user: true }` to bypass auth, then broadcasts the result on `UsersChannel` keyed by `Room`.

## Lib

- `app/lib/not_authenticated_error.rb` — `NotAuthenticatedError`. Raised by `Mutations::BaseMutation#prepare_response` and `QueryType#confirm_current_user!`, rescued in `GraphqlController#execute` and rendered as HTTP 401.

## Initializers

- `config/initializers/devise.rb` — case-insensitive + whitespace-stripped `:email`, bcrypt stretches of 11 (1 in test), password length `6..128`, reset window `6.hours`. Mailer is wired to `Devise::Mailer` but the app does not actually use it (password reset emails go out via `EmailPasswordResetWorker` through Mailgun, not Devise mailers).
- `config/initializers/doorkeeper.rb` — `grant_flows %w[password]` only (Resource Owner Password Credentials Grant); `access_token_expires_in nil` (tokens never expire); `resource_owner_from_credentials` looks up by email via `User.find_for_database_authentication` and gates on `valid_for_authentication?` so `active_for_authentication?` can veto. The `resource_owner_authenticator` block raises — there is no web sign-in flow.

## Migrations

- `db/migrate/20180115152059_create_users.rb` — original `users` table with just `email`, `name` on a `uuid` id; pre-Devise.
- `db/migrate/20190329051317_create_doorkeeper_tables.rb` — first Doorkeeper schema, integer ids.
- `db/migrate/20190329051721_drop_user_table.rb` — wipes the original users table to make room for the Devise rebuild.
- `db/migrate/20190329051901_add_devise_to_users.rb` — recreates `users` with `uuid` id and Devise columns (`encrypted_password`, `reset_password_token/_sent_at`, `remember_created_at`). Commented-out blocks for `:trackable`, `:confirmable`, `:lockable` show what was deliberately skipped.
- `db/migrate/20190329055527_drop_doorkeeper.rb` — drops the integer-id Doorkeeper tables.
- `db/migrate/20190329055638_recreate_doorkeeper_with_uuids.rb` — recreates `oauth_applications`, `oauth_access_grants`, `oauth_access_tokens` with `uuid` ids and `resource_owner_id` typed as `uuid` to match `users`.
- `db/migrate/20190403034154_add_room_and_name_to_user.rb` — adds `name` (back) and `room_id` to users.
- `db/migrate/20200423152618_remove_remember_at_from_user.rb` — drops `remember_created_at`; `:rememberable` is not in the Devise module list, so the column was dead weight.

## Factories

- `spec/factories/users.rb` — `factory :user` — email is `"anime-turtle-#{SecureRandom.uuid}@myspace.com"` (unique per build), password is the literal `"hunter2"`. Filename is plural; the factory itself is singular (`:user`).

## Specs

- `spec/models/user_spec.rb` — relationship-only model spec (per repo convention; no validation/callback specs).
- `spec/mutations/user_password_update_spec.rb` — request-type spec for `UserPasswordUpdate`; covers invalid-old-password, weak-new-password, and happy-path login-with-new-password.
- `spec/mutations/user_update_spec.rb` — request-type spec for `UserUpdate`; asserts the whitelist (only `name` updates).
- `spec/queries/user_spec.rb` — request-type spec for the `currentUser` query (and what fields render).
- `spec/workers/broadcast_users_worker_spec.rb` — worker-type spec; asserts the broadcast payload on `UsersChannel`.

## Cross-references (NOT in this feature)

- `app/controllers/application_controller.rb#current_user` and `app/controllers/graphql_controller.rb` — request-side auth glue; lives under structures, not this feature.
- `app/channels/application_cable/connection.rb` — channel-side auth; same.
- `spec/support/auth_helper.rb` — test helper; covered in `structures/testing.md`.
