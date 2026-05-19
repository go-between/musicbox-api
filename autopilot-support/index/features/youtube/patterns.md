# YouTube Integration — Patterns

## Raw `Net::HTTP`, no SDK, no gem

- `YoutubeClient` uses `Net::HTTP` directly — there is no `google-api-client`, Faraday, or HTTParty in the loop. Responses are parsed with `JSON.parse(..., symbolize_names: true)`, so all reads use symbol keys (`:items`, `:snippet`, `:contentDetails`, `:thumbnails`). If you swap in a different transport, preserve symbol-keyed dig paths or update every caller.
- The two endpoints are hard-coded URLs (`https://www.googleapis.com/youtube/v3/videos` and `.../search`). The `key` is `ENV["YOUTUBE_KEY"]` (see `.env.template`). No base-URL/config object exists.

## Failures are silently swallowed

- `YoutubeClient#get` returns `nil` for any non-`Net::HTTPSuccess` response. There is no retry, no exception, no `Airbrake.notify`, no logging — quota exhaustion, network errors, and 4xx from a bad key all look identical to "no results."
- `find` returns `nil` when the API returns no items; `search` returns `[]`. Neither caller (`Mutations::SongCreate#attrs_from_youtube!` and `Selectors::SearchResults#from_youtube`) checks for `nil`. `SongCreate` will then raise a `NoMethodError` on `video.description` if `find` returns `nil` — there is no defensive guard, by design or by oversight.
- Despite `config/initializers/airbrake.rb` being configured, this client does not opt in. Failures will surface only through the resulting Rails exception (in `SongCreate`) or as an empty search result (in `SearchResults`).

## `find` vs `search` shape divergence

- `find(youtube_id)` returns a rich `OpenStruct` with nine fields including `duration` (ISO-8601 parsed via `ActiveSupport::Duration.parse(...).to_f` — seconds as float), `youtube_tags`, `channel_*`, `published_at`, `category_id`. These map directly to the columns hydrated by `SongCreate#attrs_from_youtube!`.
- `search(query)` returns an `OpenStruct` array with only four fields (`id`, `name`, `description`, `thumbnail_url`) — matching `Types::YoutubeResult` exactly. The `id` is `videoId`, not the wrapper `id` object. Do not assume `find` and `search` results are interchangeable.
- Field names also diverge: `find` produces `title`, `search` produces `name`. The mismatch is intentional — `find` mirrors the API payload, `search` mirrors the GraphQL projection.

## Hydration is single-shot, at create time

- `YoutubeClient#find` is called exactly once per song, inside `Mutations::SongCreate#attrs_from_youtube!`, guarded by `unless song.persisted?`. There is no refresh job, no re-hydration path, no migration to backfill — once written, fields are frozen. See `features/songs/patterns.md`.
- This is why `YoutubeClient` does not cache: the only call site is already idempotent at the Song-row level.

## Search fallback ordering

- `Selectors::SearchResults#search` queries the local `Song` table first (substring `ILIKE` on `name`, excluding songs already in the user's library) and only falls back to `YoutubeClient#search` when local results are empty. Quota is spent only on novel queries. This is owned by `features/search/`; documented here to explain why `YoutubeClient#search` traffic is low and asymmetric.

## `user` parameter is dead weight (for now)

- `YoutubeClient.new(user)` stores the user on `@user` but never reads it. Both callers pass the current user out of habit. If you add per-user quotas, OAuth-tokened YouTube access, or audit logging, this is the hook.

## Test convention

- `spec/mutations/song_create_spec.rb` stubs the client with `instance_double(YoutubeClient)` and asserts `YoutubeClient` is *not* instantiated for already-persisted songs — that absence is part of the contract. No spec exercises the real HTTP path.
