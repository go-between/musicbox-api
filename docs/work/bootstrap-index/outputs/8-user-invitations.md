# Step 8 — features/user-invitations

- id: 8
- kind: produce
- verify: pass

## Changes

Created the three-file feature index at `autopilot-support/index/features/user-invitations/`:

- `map.md` — lists every CSV-classified file grouped by layer (model, GraphQL, worker, migrations, specs) with a one-line role for each. Calls out two known gaps (no `Invitation` factory; Mailgun template lives off-repo).
- `patterns.md` — non-obvious conventions: `Invitation.token` as class-method seam, `find_or_initialize_by(email, team)` idempotency, direct-HTTP Mailgun delivery (no ActionMailer) and the shared `"a mailgun worker"` example, the email-keyed `invited_user` association, the `invited_by_id`/`inviting_user` column-vs-association name divergence, the two-state enum and its lifecycle, public-mutation lookup contract, and team linkage at accept time.
- `boundaries.md` — where the feature ends (user-authentication owns User/Devise/Doorkeeper, teams owns `teams_users` join), extension points (new states, new channels, token strategy, payload variables), and do-not-build list (don't reinvent tokens, don't bypass the worker, don't add a before_create callback, don't add an email+team uniqueness validation, don't add expiry inside this feature, don't leak enumeration in accept errors).

## Verify Result

- `test -s` for all three files — pass.
- All 13 CSV-listed basenames appear in `map.md` (verified manually against `awk -F',' '$2=="User Invitation System"' feature_classification.csv`).
- `grep -nE ':[0-9]+'` across the three files — no matches outside of nothing-to-exclude (no `http`, no line numbers leaked).

## Notes

- Index rules obeyed: every reference is by path or symbol; no code blocks; no line numbers; only non-obvious info (e.g., the `invited_by_id` column-name divergence, the worker re-enqueue on already-accepted invites, the missing factory).
- Did not modify `progress.json`, `app/`, `lib/`, `db/`, `config/`, or `spec/`.
- `map.md` notes that read-side resolvers (`invitation`, `invitations`) live in the shared `QueryType` and are catalogued under `structures/resources.md` rather than duplicated here — the CSV does not list `query_type.rb` for this feature, so this stays a pointer rather than a file entry.
