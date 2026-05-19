# Team Collaboration — Patterns

## Team lifecycle: create vs. activate
- `TeamCreate` is a public surface (overrides `ready?` to bypass auth) used as a combined sign-up + team-creation entry point. It find-or-creates the owner user via `ensure_user!`, creates the `Team`, then appends `team_owner.teams << team`. The mutation returns a Doorkeeper access token, not a `Team` field — the client is expected to log in with that token and resolve the team separately.
- `TeamCreate` does not call `BroadcastTeamWorker`. There are no team-channel subscribers at the moment of creation, so the broadcast happens later when the user activates the team.
- `TeamActivate` is the only path that mutates `users.active_team_id`. Membership is enforced through `current_user.teams.exists?(id: team_id)` — do not assume callers have already authorized.

## The `teams_users` join (legacy plural-plural)
- The DB table is named `teams_users` (both sides plural), the older Rails naming convention. `TeamUser` explicitly pins `self.table_name` to that string; renaming the model or table breaks the association.
- Membership is added through the `has_many :through` macros (`user.teams << team` / `team.users << user`) — the `TeamUser` model itself is rarely instantiated directly. Specs and `TeamCreate` both use the through-association append form.
- The join carries no extra columns (just `team_id`, `user_id`, timestamps). Adding a role or per-membership setting would mean upgrading the join into a real attributed model.

## `active_team_id` as current-team context
- `User.active_team` (declared in `app/models/user.rb` as `belongs_to :active_team, optional: true, foreign_key: :active_team_id, class_name: "Team"`) is the implicit "current team" for the rest of the app. It is `optional`, so newly-created users start with no active team.
- `TeamChannel#subscribed` reads `current_user.active_team` directly — if the user has not yet called `teamActivate`, subscription is rejected. The team channel is therefore unusable until activation has happened at least once.
- The activation flow broadcasts to *both* the previous and the new team so clients subscribed to either channel see the membership/state transition.

## Broadcast fan-out via `BroadcastTeamWorker`
- The worker re-executes a hard-coded GraphQL query (`team(id:) { rooms { ... users { ... } } }`) inside Sidekiq using `MusicboxApiSchema.execute` with `context: { override_current_user: true }`. This is the standard pattern for workers that need to render GraphQL payloads without a real request user — the schema's auth layer honors that context flag.
- The payload shape is fixed inside the worker, not driven by the subscribed client. Adding a new field to the team-channel payload means editing the GraphQL string in `BroadcastTeamWorker#query`, not changing `TeamType`.
- Broadcast key is the `Team` instance (`TeamChannel.broadcast_to(Team.find(team_id), ...)`) so streams are scoped per team record.

## Rooms attach to a team via column, not association on Team
- The team↔room link is owned by `Room` through the `team_id` column added in `20191231014524_add_team_to_room.rb`. `Team` only declares `has_many :rooms`; the inverse `belongs_to :team` and any room-side validations live in `features/rooms/`.
- The room broadcast payload is rendered by the team broadcast worker (rooms are nested under `team { rooms { ... } }` in the worker's query) — so room-list changes propagate to clients through the team channel, not a dedicated room-list channel.
