# Step 7 — feature: user-authentication

- id: 7
- kind: produce
- verify: pass

## Changes

Wrote the three index files for the `user-authentication` feature:

- `autopilot-support/index/features/user-authentication/map.md` — One line per file in scope, grouped by layer (model, mutations, types, channels, workers, lib, initializers, migrations, factories, specs). Also notes the cross-references (`application_controller.rb`, `graphql_controller.rb`, `application_cable/connection.rb`, `spec/support/auth_helper.rb`) that participate in auth but live under structures, not this feature.
- `autopilot-support/index/features/user-authentication/patterns.md` — Devise modules in/out, Doorkeeper password-grant-only with non-expiring tokens, the three separate `current_user` resolution paths (controller / GraphQL field / ActionCable), the `override_current_user` flag (queries only, not mutations), `NotAuthenticatedError` lifecycle (raised in schema, rescued in `GraphqlController`, rendered as a bare 401), the `reset_password(new, new)` behavior in `UserPasswordUpdate`, whitelist-only `UserUpdate#update_with`, case-insensitive email handling, bcrypt cost (`Rails.env.test? ? 1 : 11`), the create/drop/recreate UUID migration graveyard, `UsersChannel#unsubscribed` as the "user left room" signal, and why `start_password_reset!` exists.
- `autopilot-support/index/features/user-authentication/boundaries.md` — What this feature owns, where it ends (invitations → `features/user-invitations/`, reset flow → `features/password-reset/`, teams → `features/teams/`, rooms → `features/rooms/`, library/tags/playlists → their respective features), extension points (new Devise module, account-lock via `active_for_authentication?`, new updatable user field, new auth strategy via Doorkeeper grant flow, force-logout via token revocation), and do-not-build list (no custom session middleware, no registration mutation here, no `:confirmable` flow, no auth resolver that bypasses Doorkeeper, no direct `set_reset_password_token` calls, no mass-assignment in `UserUpdate`, no `override_current_user` from mutations, no Devise mailers).

## Verify Result

```
$ for f in autopilot-support/index/features/user-authentication/{map,patterns,boundaries}.md; do test -s "$f" || echo "EMPTY: $f"; done
(no output — all three files non-empty)

$ awk -F',' '$2=="User Authentication & Management"' feature_classification.csv | cut -d',' -f1 | while read p; do
    base=$(basename "$p")
    grep -q "$base" autopilot-support/index/features/user-authentication/map.md || echo "MISSING in map: $base"
  done
(no output — every CSV basename appears in map.md)

$ grep -rnE ':[0-9]+' autopilot-support/index/features/user-authentication/ | grep -v 'http' | head
(no output — no line-number leaks)
```

All three verification commands passed.

## Notes

- Did not modify `progress.json`, `app/`, `lib/`, `db/`, `config/`, or `spec/`.
- Index rules obeyed throughout: pointed at file paths (never pasted code), referenced symbols by name (never line numbers), kept content to non-obvious observations (the Devise/Doorkeeper handoff in `resource_owner_from_credentials`, why three separate `current_user` resolvers exist, why the migration history has create/drop/recreate pairs, why `UsersChannel#unsubscribed` is the leave-room signal).
- `spec/support/auth_helper.rb` is explicitly noted in `map.md` as a cross-reference rather than as a member of this feature, per the step instructions.
- Token-via-query-string note in patterns.md mentions the security implication (tokens land in server logs) because that's a real operational watch-out that isn't visible from the code.
