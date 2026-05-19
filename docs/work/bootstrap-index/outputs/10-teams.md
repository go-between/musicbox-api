# Step 10 — features/teams

- id: 10
- kind: produce
- verify: pass

## Changes

Wrote three files under `autopilot-support/index/features/teams/`:

- `map.md` — every basename from the CSV (`Team Collaboration`) listed with a one-line role, grouped by layer: Models, GraphQL Types, GraphQL Mutations, ActionCable, Workers, Migrations, Specs. Notable callouts: `TeamUser` pins legacy `teams_users` table name; `TeamType` exposes only id/name/rooms/users; `team_id` was added to rooms in a teams-feature migration; `team_create_spec.rb` is misleadingly described as "Invitation Create".
- `patterns.md` — covers (1) team lifecycle: `TeamCreate` is a public combined sign-up that returns a Doorkeeper token (no broadcast); `TeamActivate` is the only mutation that mutates `active_team_id` and authorizes via `current_user.teams.exists?`; (2) the legacy plural-plural `teams_users` join with no extra columns; (3) `User#active_team` as implicit current-team context and how `TeamChannel#subscribed` rejects when nil; (4) `BroadcastTeamWorker` re-executing a hard-coded GraphQL query under `override_current_user: true` and broadcasting per-team; (5) rooms attach via a column on Room (not on Team) and ride out through the team-channel payload.
- `boundaries.md` — extension points for new team fields (must update the worker query, not just `TeamType`) and team-scoped settings (Team vs. promoted join model); do-not-build list (no bypassing `team_users`, no team-scoped mutations that accept `team_id`, no hand-rolled membership checks, no second owner relation, no assuming `TeamType` changes propagate to clients without worker-query edits); where teams end (rooms own their lifecycle in `features/rooms/`; member onboarding lives in `features/user-invitations/`; the Doorkeeper token returned by `TeamCreate` is owned by `features/user-authentication/`; `active_room_id` belongs to rooms).

## Verify Result

- `test -s` for all three files — pass (none empty).
- CSV-basename coverage in `map.md` — pass (all 15 basenames present, no `MISSING in map` output).
- `grep -nE ':[0-9]+' ... | grep -v http` — no matches (no line numbers leaked).

## Notes

- Index rules obeyed: pointed to files, no line numbers, no code fences, only non-obvious information (Devise/Doorkeeper details left to the auth feature; legacy `teams_users` table naming flagged; worker GraphQL string treated as the canonical broadcast payload contract).
- Scope respected: no edits to `progress.json`, `app/`, `lib/`, `db/`, `config/`, `spec/`, or files outside `autopilot-support/index/features/teams/` and this work log.
