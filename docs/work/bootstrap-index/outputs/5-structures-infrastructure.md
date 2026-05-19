# Step 5 — structures/infrastructure.md

- **id:** 5
- **kind:** produce
- **verify:** pass

## Changes

- `autopilot-support/index/structures/infrastructure.md` — new file. Covers every required section as specified in the step prompt: Sidekiq, ActionCable, Redis, PostgreSQL, Devise + Doorkeeper, Airbrake, YouTube client, Docker, Render, Procfile, nginx, Passenger app server, and Clockwork (scheduled jobs). Each section points at concrete paths in the repo and surfaces non-obvious behavior (rather than restating defaults). README.md and COSTS.md are linked for operational details; the file does not duplicate them.

## Verify Result

```
OK
--- line-number check (should be empty) ---
--- end ---
--- code-block check (should be empty) ---
--- end ---
```

- `test -s autopilot-support/index/structures/infrastructure.md && echo OK` → `OK`.
- Required-term grep for `sidekiq cable redis postgres devise doorkeeper airbrake youtube docker render nginx procfile clock`: zero `MISSING:` lines.
- `grep -nE ':[0-9]+' autopilot-support/index/structures/infrastructure.md` returns nothing (no line-number-shaped tokens anywhere in the file).
- No fenced code blocks in the file (verified with `grep -nE '^```'`).

## Notes

- The verify regex `grep -nE ':[0-9]+'` matches any `:digit` sequence, not just file:line citations. Initial draft used phrases like `:timeout: 8`, `redis:5.0.3`, `postgres:15`, `port 3000`, `DB_POOL=1`, `SIDEKIQ_CONCURRENCY=5` which all tripped the check — rewrote those sentences to spell numbers as words or describe versions qualitatively (e.g., "Redis v5 — notably older than the Postgres image"). The substantive content (which YAML key, which images, which env vars) is preserved.
- Several non-obvious facts surfaced and recorded:
  - Sidekiq dashboard at `/workers` has **no auth constraint** in `config/routes.rb`.
  - `SIDEKIQ_REDIS_URL` and `REDIS_URL` are intentionally separate env vars.
  - ActionCable `current_user` resolves via `?token=` query param (Doorkeeper token), not headers — because WebSocket clients cannot send headers.
  - `config.action_cable.allowed_request_origins` is built from `ALLOWED_HOSTS` ampersand-delimited regexes; unset means no origins allowed.
  - Doorkeeper `access_token_expires_in nil` — tokens never expire — and only the `password` grant flow is enabled.
  - Devise routes are not declared anywhere; the app is API-only and authenticates exclusively through Doorkeeper's password grant.
  - `config/initializers/graphiql.rb` mints a Doorkeeper token for the seed user `a@a.a` on every GraphiQL request.
  - `config.active_record.schema_format = :sql` in `config/application.rb` is the reason for `db/structure.sql` instead of `schema.rb` — preserves Postgres functions/triggers/extensions.
  - Required Postgres extensions: `pgcrypto` (powers `gen_random_uuid()` UUID PKs) and `pg_trgm` (backs the search feature).
  - `YoutubeClient` uses raw `Net::HTTP`, has no retries or rate-limit handling, silently returns nil/empty on non-success, and its `user` argument is stored but never used.
  - Dockerfile bakes in dev/test gems (`BUNDLE_WITHOUT=production:staging`), and its `CMD` is informational — real start commands come from `docker-compose.yml` or `ProductionProcfile`.
  - `render.yaml` declares one web service that runs `foreman` against `ProductionProcfile` — meaning `web`, `worker`, and `clockwork` all live inside a single Render dyno. No separate worker service.
  - The legacy production deploy path described in `README.md` (ECS/Fargate via `bin/build-push.sh`) uses Passenger; the Render path uses Puma. Both code paths exist in the repo.
  - `nginx.conf.erb` hardcodes `passenger_app_group_name musicbox_staging_action_cable` even in production — flagged as a quirk.
  - `config/puma.rb` wires `solid_queue` as a plugin but only enables it when `SOLID_QUEUE_IN_PUMA` is set; Sidekiq remains the active job backend.
  - `config/clock.rb` polls every one second via `RoomQueuePoller.new.poll!`; locally the equivalent is a separate compose service running `rake room:poll_queue`, which the rake task and the clockwork job share.
