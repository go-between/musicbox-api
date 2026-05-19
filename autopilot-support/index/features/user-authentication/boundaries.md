# User Authentication & Management — Boundaries

What this feature owns, where it ends, and what not to build inside it.

## What this feature owns

- The `User` model's auth surface: Devise modules, password hashing, `valid_password?`, `valid_for_authentication?`, `reset_password`, and `start_password_reset!`.
- Doorkeeper configuration and the OAuth password-grant flow (token issuance, validation, `current_user` lookup from `resource_owner_id`).
- The `users`/`oauth_*` table schemas.
- `Mutations::UserUpdate` and `Mutations::UserPasswordUpdate`.
- `Types::UserType` (the public projection of a User).
- `UsersChannel` (presence broadcast for the room) and `BroadcastUsersWorker`.
- `NotAuthenticatedError` and its rescue path.

## Where this feature ends

- **Invitations and onboarding** — Anything that *creates* a `User` (acceptance tokens, the `Invitation` model, `invited_user_name`, `EmailInvitationWorker`) is `features/user-invitations/`. This feature treats the `User` row as already existing.
- **Password reset** — The mailer-driven flow (`EmailPasswordResetWorker`, the reset-by-token mutation) is `features/password-reset/`. This feature owns `start_password_reset!` on the model but not the flow that calls it. `Mutations::UserPasswordUpdate` (changing a password while logged in) stays here; `Mutations::PasswordReset*` (anonymous, token-bearing) does not.
- **Teams and memberships** — `Team`, `TeamUser`, `team_users`/`teams` associations, team activation, and `active_team_id` mechanics live in `features/teams/`. This feature only declares the `has_many :teams, through: :team_users` association on `User` because `User` is its home class.
- **Rooms and active-room logic** — `active_room`/`active_room_id`, room joining/leaving as a domain concept, and the `room` table itself live in `features/rooms/`. `UsersChannel#unsubscribed` clearing `active_room_id` lives here because it is the *presence-of-the-User* edge, but the meaning of `active_room` belongs to rooms.
- **Library, tags, playlists, listens** — All `User`-rooted associations (`library_records`, `songs`, `tags`, `room_playlist_records`) are owned by their respective feature directories.

## Extension points

- **New Devise module** — Add to the `devise` line in `app/models/user.rb`; add a migration adding any required columns; update the commented-out blocks in `db/migrate/20190329051901_add_devise_to_users.rb` mentally (don't backfill the old migration). Confirm `valid_for_authentication?` semantics still match — see Patterns.
- **Account lock without `:lockable`** — Override `active_for_authentication?` on `User`. Token issuance in `config/initializers/doorkeeper.rb` already routes through `valid_for_authentication?` and will silently refuse tokens for inactive users.
- **A new updatable user field** — Add the column migration, add the `argument :field, …` line to `UserUpdateInputObject` in `app/graphql/mutations/user_update.rb`, and add the corresponding `hsh[:field] = user[:field] if user[:field].present?` inside `update_with`. Also add the field to `app/graphql/types/user_type.rb` if it should be readable.
- **A new auth strategy** — Add a Doorkeeper grant flow in `config/initializers/doorkeeper.rb` (`grant_flows`) and implement the matching block (`authorization_code` → set `resource_owner_authenticator`). All three `current_user` resolvers (`ApplicationController`, `BaseMutation`/`QueryType` via context, `ApplicationCable::Connection`) work off `Doorkeeper::AccessToken`, so they require no change. For something that is *not* a Doorkeeper token (e.g., signed JWT, API key), all three resolvers must be touched.
- **Forcing a logout** — Revoke the user's `Doorkeeper::AccessToken` rows (set `revoked_at`). No app-side code exists for this — add a mutation under this feature if needed, and reuse `current_user.access_grants`/`access_tokens` via the Doorkeeper associations.

## Do not build here

- **Custom session middleware / cookies / CSRF for the API.** The app is `ActionController::API` (`app/controllers/application_controller.rb`), there is no session store, and `clean_up_csrf_token_on_authentication` is irrelevant. Authentication is bearer-token only — do not add a cookie path.
- **A user registration mutation under this feature.** Sign-up belongs to `features/user-invitations/` (invitation-only). If product direction changes and open sign-up is added, create a new feature directory rather than reviving `:registerable`.
- **A `confirm_email` flow.** `:confirmable` is intentionally not enabled and no `confirmation_token` column exists.
- **A `current_user` resolver that bypasses Doorkeeper.** Don't read raw bearer tokens, don't decode JWTs, don't query `oauth_access_tokens` directly. Go through `doorkeeper_token` in controllers and `Doorkeeper::AccessToken.by_token` in `ApplicationCable::Connection`.
- **Calling `set_reset_password_token` directly from anywhere outside `User`.** It is protected on purpose; go through `User#start_password_reset!`.
- **Mutations or services that mass-assign to `User`.** `Mutations::UserUpdate` is whitelist-only on purpose; preserve that pattern.
- **Broadcasting from a mutation under this feature using `override_current_user: true`.** The flag is honored by queries (`QueryType#confirm_current_user!`) but not by mutations (`BaseMutation` always requires auth). Re-broadcast via a worker, not a server-side mutation call.
- **Devise mailers.** `config.mailer = "Devise::Mailer"` is set but unused — outbound email goes through Mailgun workers under `features/password-reset/` and `features/user-invitations/`. Do not wire `ActionMailer` SMTP into this feature.

## Schema invariants

- `users.id` is `uuid`. So is `oauth_access_tokens.resource_owner_id` and `oauth_access_grants.resource_owner_id`. Any new auth table referencing a user must use `t.uuid :user_id` (or `t.references :user, type: :uuid`).
- `users.email` has a unique index; Devise downcases and strips whitespace on write.
- `users.reset_password_token` has a unique index; reset tokens are single-use across all users.
- Doorkeeper's `oauth_access_tokens.token` and `refresh_token` both carry unique indexes.

## Test boundary

Specs for this feature live in `spec/{models,mutations,queries,workers}/user*` and `spec/factories/users.rb`. The cross-cutting `spec/support/auth_helper.rb` is documented in `structures/testing.md` and **is not in this feature** — it provides the `Doorkeeper::AccessToken.create!` shortcut used by every other feature's request specs, so changes there ripple everywhere.
