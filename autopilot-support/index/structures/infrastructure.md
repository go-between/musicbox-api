# Infrastructure

Runtime and operational infrastructure for musicbox-api. This file points at the configuration files and surfaces non-obvious behavior. For day-to-day operational details (deploys, ECS, RDS tunneling) see `README.md`. For ongoing cost tracking see `COSTS.md`.

## Sidekiq

- `config/sidekiq.yml` — concurrency is five and the `timeout` value (eight seconds) is unusually aggressive (Sidekiq's default is twenty-five seconds). Every queue is weighted one, so they round-robin rather than prioritize. The queue names map one-for-one to the workers in `app/workers/` — when a worker is added, both the worker class's queue option and this YAML must be updated or the job won't be picked up.
- `app/workers/` — one worker per Sidekiq queue. `queue_management_worker.rb` advances room queues; the `broadcast_*_worker.rb` family fans channel updates out via ActionCable; `email_invitation_worker.rb` and `email_password_reset_worker.rb` send Devise-driven mail.
- `config/initializers/sidekiq.rb` — both server and client are configured against `ENV["SIDEKIQ_REDIS_URL"]`, **not** `REDIS_URL`. The Sidekiq Redis can be a different instance/db than the ActionCable Redis (docker-compose happens to point both at the same host). Log level is read from `ENV["LOG_LEVEL"]` independent of Rails' logger.
- `config/routes.rb` — the Sidekiq dashboard is mounted at `/workers` (not `/sidekiq`). It is **not behind any authentication constraint** — anyone who can reach the host can see and replay jobs. See `README.md` for the local URL.

## ActionCable

- `config/cable.yml` — uses the `redis` adapter in every non-test environment (test uses the in-memory `test` adapter). `channel_prefix` differs per environment so a single Redis can host multiple deploys safely. `REDIS_URL` is the variable (separate from `SIDEKIQ_REDIS_URL`).
- `config/routes.rb` mounts the server at `/cable`.
- `app/channels/application_cable/connection.rb` — auth happens via `?token=` query param resolved through `Doorkeeper::AccessToken.by_token`, not Devise sessions or the `Authorization` header. WebSocket clients cannot use headers, so the bearer token rides in the URL.
- `app/channels/application_cable/channel.rb` — every channel inherits a `subscribed` hook that rejects unless `current_user.active_room` is set and then `stream_for` that room. Per-channel subclasses (e.g., `app/channels/now_playing_channel.rb`, `room_playlist_channel.rb`, `message_channel.rb`, `pinned_messages_channel.rb`, `record_listens_channel.rb`, `team_channel.rb`, `users_channel.rb`) inherit this behavior — they do not redeclare `subscribed`.
- `config/application.rb` — `config.action_cable.allowed_request_origins` is built from `ENV["ALLOWED_HOSTS"]` (ampersand-delimited regexes). An unset `ALLOWED_HOSTS` means no origins are allowed.
- `nginx.conf.erb` — `/cable` is given its own `passenger_app_group_name` and `passenger_force_max_concurrent_requests_per_process 0;` so long-lived WebSocket connections don't block normal Passenger workers.

## Redis

Used by both Sidekiq (`SIDEKIQ_REDIS_URL`) and ActionCable (`REDIS_URL`). These are separate env vars deliberately — production may point them at different instances even though `docker-compose.yml` uses one. There is **no `Rails.cache` Redis** configured; cache store defaults to in-memory.

## PostgreSQL

- `config/database.yml` — single `default` block keyed off `ENV["DATABASE_URL"]`. Pool size follows `RAILS_MAX_THREADS` (default `5`). The `production` block points at the `musicbox-api_staging` database — the URL env var overrides this in practice, but the literal default is suspicious.
- `db/structure.sql` — the schema dump is SQL rather than `schema.rb` because `config.active_record.schema_format = :sql` in `config/application.rb`; this preserves PostgreSQL-specific functions, triggers, and extensions that `schema.rb` would silently drop.
- Required extensions, enabled in migrations and present in `db/structure.sql`:
  - `pgcrypto` (`db/migrate/20171228003631_enable_pgcrypto_extension.rb`) — powers `gen_random_uuid()` default for every primary key (UUIDs are the project-wide default; see `config/application.rb` generator config).
  - `pg_trgm` (`db/migrate/20200226234544_enable_pgtrgm_extension.rb`) — backs the trigram-based search feature.

## Devise + Doorkeeper

- `config/initializers/devise.rb` — almost entirely defaults; the only meaningful changes are `password_length` (`6..128`) and `reset_password_within` (`6.hours`). No mailer host is set here.
- `config/initializers/doorkeeper.rb` — `grant_flows %w[password]` only (no authorization code, no client credentials), and `access_token_expires_in nil` (**tokens never expire**). `resource_owner_authenticator` raises by design — the API only uses `resource_owner_from_credentials` (password grant) to mint tokens against Devise's `valid_password?`.
- `config/routes.rb` — Doorkeeper is mounted via `use_doorkeeper` inside `scope path: "/api"` → `scope path: "/v1"`, so OAuth endpoints live under `/api/v1/oauth/*`. Devise routes are **not** declared — the app does not expose Devise's controllers; authentication is exclusively through Doorkeeper's password grant.
- `config/initializers/graphiql.rb` — local GraphiQL injects an `Authorization: Bearer <token>` header by minting a Doorkeeper token for the seed user `a@a.a` on each request. If that user doesn't exist, the GraphiQL page fails — see `README.md`.

## Airbrake

- `config/initializers/airbrake.rb` — exception tracking; uses `AIRBRAKE_ID` / `AIRBRAKE_SECRET` env vars. `ignore_environments` is `%w[test]` — staging and development both report. `blocklist_keys` filters `/password/i` and `/authorization/i` from payloads. Errors are sent through `Airbrake::Rails.logger` rather than STDOUT.

## YouTube client

- `app/lib/youtube_client.rb` — the only external HTTP integration. Hits two YouTube Data API v3 endpoints: `videos` (for `find(youtube_id)`, returns snippet + contentDetails including ISO-8601 `duration` parsed via `ActiveSupport::Duration.parse`) and `search`. Reads the API key from `ENV["YOUTUBE_KEY"]`. Uses raw `Net::HTTP` (not Faraday or HTTParty) and **has no rate-limit handling, no retries, and no quota tracking** — non-`Net::HTTPSuccess` responses silently return `nil` / `[]`. The `user` argument is stored but never consulted.

## Docker

- `Dockerfile` — Ruby `3.4.4`, bundler `2.6.7`. `BUNDLE_WITHOUT=production:staging` is set at build time, so the image bakes in dev/test gems and excludes production/staging-only ones — surprising for an image used in non-dev environments. `passenger-config install-standalone-runtime --auto` and `build-native-support` are pre-run so the container boots fast. The final `CMD` is informational only (`echo "Commands: ..."`); real start commands are supplied by `docker-compose.yml` or `ProductionProcfile`.
- `docker-compose.yml` — four services: `db` (Postgres v15), `redis` (Redis v5 — notably older than the Postgres image), `app` (Passenger fronted by the bundled nginx template), `app-poll-room-queue` (runs `rake room:poll_queue` as a long-running process — the local equivalent of `config/clock.rb`'s `room-poll` job), and `app-sidekiq-workers` (runs `bundle exec sidekiq` with a low db pool and matching Sidekiq concurrency). All app containers share the build via YAML anchors. `bin/wait-for-it.sh` gates startup on db/redis readiness.

## Render

- `render.yaml` — defines a **single web service** that runs `bin/foreman start -f ./ProductionProcfile`. This means foreman fans the Procfile's web/worker/clockwork processes out inside a single Render web dyno, which is unusual (typically each Procfile process would be its own Render service). There is **no separate worker service declared**. Build is delegated to `bin/render-build.sh`. Real production may live elsewhere — `README.md` describes an ECS/Fargate deploy path via `bin/build-push.sh`, which predates this file.

## Procfile

- `ProductionProcfile` (note the name — there is no plain `Procfile`) — three processes started by foreman: `web` (`bin/puma -C config/puma.rb`), `worker` (`bin/sidekiq`), `clockwork` (`bin/clockwork config/clock.rb`). Despite `passenger` being in the Gemfile and `nginx.conf.erb` being shipped, the Render path uses Puma — Passenger is used for the Docker image's local serving and for the legacy ECS deploy.

## nginx

- `nginx.conf.erb` — a Passenger Standalone Nginx config template (not a freestanding nginx config). Notable: `client_max_body_size 1024m;` (1 GB requests allowed), `access_log off;` (no request logs from nginx — Rails STDOUT only), gzip on, `underscores_in_headers on;`, and the `/cable` location override described above. The `passenger_app_group_name` is hardcoded as `musicbox_staging_action_cable` — same group name in production, which means production and staging both name the cable app group "staging" if they share the file.

## Passenger app server

- `gem "passenger"` in `Gemfile` (`6.0.27`). Passenger powers the Docker image (`docker-compose.yml` runs `passenger start -p 3000 --nginx-config-template nginx.conf.erb`). It is **not** used on the Render deploy — that uses Puma via `ProductionProcfile`. `config/puma.rb` configures Puma threads from `RAILS_MAX_THREADS` (default `3`) and listens on `PORT`; the `solid_queue` plugin is wired but only enabled when `SOLID_QUEUE_IN_PUMA` is set (it currently is not — Sidekiq remains the job backend).

## Clockwork (scheduled jobs)

- `config/clock.rb` — a single job: `every(1.second, "room-poll") { RoomQueuePoller.new.poll! }`. Runs the room queue poller once per second. This is the cron-equivalent backbone for advancing playback across all active rooms. Started by the `clockwork` line in `ProductionProcfile`; locally, the equivalent is the `app-poll-room-queue` service in `docker-compose.yml`, which runs `rake room:poll_queue` instead of clockwork (the rake task and the clockwork job both poll the same `RoomQueuePoller`).
