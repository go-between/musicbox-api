# Team Collaboration — Boundaries

## Extension points

### New team-level fields
- Add columns to `teams` via a new migration, expose them on `app/graphql/types/team_type.rb`, and — if they should reach connected clients — extend the GraphQL string in `app/workers/broadcast_team_worker.rb`. The worker's query is the canonical team-channel payload; `TeamType` fields not listed there will not appear in broadcasts.
- For team-scoped settings, consider whether the value lives on `Team` (single source of truth) or on the `teams_users` join (per-member settings). The join is currently bare; promoting it to an attributed model is the right move if you need per-membership state.

### New team mutations
- New mutations should derive scope from `current_user.active_team`, not from a `team_id` argument. `TeamActivate` is the only mutation that takes a `team_id` and it does so to switch context. Other mutations should read context, not accept it.
- If a new flow needs to broadcast, call `BroadcastTeamWorker.perform_async(team_id)` after persisting, the same way `TeamActivate` does.

## Do not build

- **Do not bypass `team_users` for membership.** Always go through `user.teams <<` / `team.users <<` (the `has_many :through` macros). Direct `TeamUser.create!` calls are technically possible but skip the association cache and complicate test setup; nothing in the codebase does this today.
- **Do not bake team-scoping into individual mutations.** Resolve the team from `current_user.active_team` rather than accepting a `team_id` argument. Forcing every client call to pass a team id reopens auth questions the activation step has already settled.
- **Do not hand-roll an auth check against `team.users`.** Use `current_user.teams.exists?(id:)` (as `TeamActivate` does); it is shorter and uses the through-association without loading user records.
- **Do not extend `TeamType` and assume clients will see it on the channel.** The broadcast payload is governed by the GraphQL string inside `BroadcastTeamWorker`, not the type definition.
- **Do not add a second `belongs_to` for owner with a different name.** `Team#owner` is the only owner concept; renaming it or layering a co-owner relation should be discussed first since `TeamCreate` and several specs encode the single-owner assumption.

## Where teams end

- **Rooms** belong to a team (`rooms.team_id`), but the room lifecycle (creation, activation, ownership) lives in `features/rooms/`. The teams feature only knows that rooms hang off a team and that the broadcast worker nests them into the team payload.
- **User invitations** — onboarding users into an existing team is the invitation feature's responsibility. `TeamCreate` handles the *initial* owner sign-up only; subsequent member onboarding lives in `features/user-invitations/`.
- **Authentication and the Doorkeeper token returned by `TeamCreate`** are owned by `features/user-authentication/`. The `access_token_for` helper and the Devise validations the mutation relies on are documented there.
- **`User#active_room_id`** mirrors the active-team pattern but belongs to `features/rooms/`; the teams feature only owns `active_team_id`.
