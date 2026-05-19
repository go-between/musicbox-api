# Team Collaboration — Map

## Models
- `app/models/team.rb` — Team root; `belongs_to :owner` (User), `has_many :rooms`, and `has_many :users, through: :team_users`. Owner is just an FK column on `teams`, not a join.
- `app/models/team_user.rb` — Join model for the `teams`/`users` many-to-many. Pins `self.table_name = "teams_users"` because the underlying table uses the legacy plural-plural Rails name.

## GraphQL — Types
- `app/graphql/types/team_type.rb` — Public `Team` type exposing `id`, `name`, `rooms`, and `users`. No mutation-side fields; team membership is read through this surface.

## GraphQL — Mutations
- `app/graphql/mutations/team_create.rb` — Creates a team plus (find-or-create) owner user in one call, attaches the owner to the team, and returns a Doorkeeper access token. Overrides `ready?` to skip the default auth (this is a sign-up surface). `TeamOwnerInputObject` is defined inline as a nested input.
- `app/graphql/mutations/team_activate.rb` — Sets `current_user.active_team_id`. Authorizes by checking `current_user.teams.exists?(id:)` before flipping, then fans out broadcasts to the previous and the newly active team.

## ActionCable
- `app/channels/team_channel.rb` — Broadcasts per-team state to subscribers. Rejects subscription when `current_user.active_team` is nil; streams keyed by the user's currently active team object.

## Workers
- `app/workers/broadcast_team_worker.rb` — Sidekiq worker on the `broadcast_team` queue. Re-executes a hard-coded GraphQL team query under `override_current_user: true` and pushes the result to `TeamChannel.broadcast_to(Team.find(team_id), ...)`. Called from `TeamActivate` for both the previous and the newly active team.

## Migrations
- `db/migrate/20191231014000_create_teams.rb` — Creates `teams` with UUID PK, `name`, and `owner_id` (no FK constraint).
- `db/migrate/20191231014524_add_team_to_room.rb` — Adds `team_id` UUID column to `rooms`; rooms-belong-to-team is wired here, not in a teams-side migration.
- `db/migrate/20191231015122_create_teams_users.rb` — Creates the join table under the legacy plural-plural name `teams_users` (UUIDs, indexes on both FKs, timestamps).
- `db/migrate/20191231020447_add_active_team_to_users.rb` — Adds `active_team_id` UUID column to `users` to track the user's current team context.

## Specs
- `spec/factories/team.rb` — `:team` factory; auto-creates an owner via `create(:user)`. No `users` association is built — tests append via `team.users <<` or `create(:user, teams: [team])`.
- `spec/models/team_spec.rb` — Relationship coverage: owner FK, users via the join, and rooms-belong-to-team (creating rooms with `team:` keyword).
- `spec/mutations/team_activate_spec.rb` — Covers success (switching active team across two teams) and the "not a member" rejection. Demonstrates the `create(:user, teams: [team])` factory pattern.
- `spec/mutations/team_create_spec.rb` — Covers new-user and existing-user team creation (including case-insensitive email match) and the two failure paths (bad password for existing user, insecure password for new user). Note the `describe` string is misleadingly named "Invitation Create".
