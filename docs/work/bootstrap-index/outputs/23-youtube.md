# Step 23 — features/youtube

- id: 23
- kind: produce
- verify: pass

## Changes

Wrote three files under `autopilot-support/index/features/youtube/`:

- `map.md` — every basename from the CSV (`YouTube Integration`) listed with a one-line role, grouped by layer: Client, GraphQL surface, Schema. Notable callouts: `YoutubeClient` accepts a `user` but never reads it; `find` and `search` return different `OpenStruct` shapes (nine fields vs. four, `title` vs. `name`); `Types::YoutubeResult` joins `Types::SongType` as a member of the search-result union (owned by `features/search/`); `youtube_id`, `thumbnail_url`, `license`, `licensed`, `youtube_tags` live physically on `songs` (owned by `features/songs/`) but their shape is defined here.
- `patterns.md` — covers (1) raw `Net::HTTP` (no SDK/Faraday), symbol-keyed JSON, hard-coded URLs, `ENV["YOUTUBE_KEY"]`; (2) all failures swallowed as `nil`/`[]` — no retries, no `Airbrake.notify`, no logging, despite `config/initializers/airbrake.rb` being configured — and the latent `NoMethodError` in `SongCreate` when `find` returns nil; (3) deliberate shape divergence between `find` and `search` (`title` vs. `name`, full vs. minimal payload); (4) single-shot hydration at create time (`unless song.persisted?`) explaining why no caching exists in the client; (5) the local-first/YouTube-fallback policy in `Selectors::SearchResults` explaining low quota usage; (6) the unused `@user` field as the hook for per-user quota/auth; (7) test convention — client is always stubbed, no live HTTP spec.
- `boundaries.md` — extension points for new YouTube endpoints (mirror the param/`get`/`OpenStruct` pattern), alternative providers (sibling `*Client` class in `app/lib/`, not branching inside `YoutubeClient`), per-user OAuth via the unused `@user`, real error handling (must coordinate with `SongCreate` to avoid trading silent failures for raised `NoMethodError`); do-not-build list (no direct YouTube HTTP from controllers/mutations/channels/workers — go through the client; no caching at this layer — caller's concern; no rate-limit/quota tracking; no "refresh metadata" job — hydration is intentionally single-shot per `features/songs/`; no reuse of `Types::YoutubeResult` for non-search payloads; no proliferation of sibling YouTube types); where YouTube ends (`Song` persistence and identity in `features/songs/`; search-UI composition in `features/search/`; recommendations and library are downstream); schema invariants for `youtube_id` (string, indexed but not uniquely constrained) and `youtube_tags` (`string[]` default `[]`); test boundary — `YoutubeClient` itself has no spec, only stubbed callers.

## Verify Result

- `test -s` for all three files — pass (none empty).
- CSV-basename coverage in `map.md` — pass (all 4 basenames present: `youtube_result_type.rb`, `youtube_client.rb`, `20190319122943_add_youtube_id_to_songs.rb`, `20200415022511_add_youtube_details_to_songs.rb`; no `MISSING in map` output).
- `grep -nE ':[0-9]+' ... | grep -v http` — no matches (no line numbers leaked). Initial pass flagged `1:1` (ratio idiom) — rewritten as "map directly" to avoid the false positive and keep verify clean.

## Notes

- Index rules obeyed: pointed to files, no line numbers, no code fences, only non-obvious information (Song persistence behavior cross-referenced to `features/songs/`, search composition cross-referenced to `features/search/`, Airbrake config presence noted but absence of opt-in flagged here).
- Cross-feature consistency: matches the description of `YoutubeClient` already in `structures/modules.md` and `structures/infrastructure.md` (Net::HTTP, no rate-limit handling, silent `nil`/`[]` on failure, unused `user` arg).
- Scope respected: no edits to `progress.json`, `app/`, `lib/`, `db/`, `config/`, `spec/`, or files outside `autopilot-support/index/features/youtube/` and this work log.
