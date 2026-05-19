# Music Statistics — Map

## GraphQL query entry
- `app/graphql/types/query_type.rb` — Defines the `unwound` root field and resolver (arguments: `year`, `team_id`, `user_id?`, `week?`, `song_name?`). The resolver instantiates `Unwound` and returns its `#call` hash; no auth gate is applied at the field level beyond what the schema enforces globally.

## GraphQL response shapes
- `app/graphql/types/unwound_type.rb` — Top-level return type. Seven fields, all non-null arrays, exposing both totals (`team_plays`, `top_plays`, `top_approvals`, `team_approvals`, `song_plays`) and time-series (`top_plays_over_time`, `song_plays_over_time`). Field names match the `Unwound#call` hash keys 1:1 — keep them in lockstep.
- `app/graphql/types/unwound_count_type.rb` — Repeated row shape `{ label, count, length }` used for every totals list. `length` is "duration in seconds" for play lists, but is overloaded as "approval received" inside `team_approvals` rows.
- `app/graphql/types/unwound_count_per_week_type.rb` — Wraps a `label` (song name) with `plays: [UnwoundCount]`. The inner `UnwoundCount` rows' `label` is a bucket index (cweek number when year-scoped, day-of-week 0..6 when week-scoped).

## Aggregation services
- `app/lib/unwound.rb` — The library object behind the GraphQL `unwound` query. PORO that owns all aggregation SQL: groups `RoomPlaylistRecord` by user/song, `RecordListen` by `approval`, and emits `UnwoundCount`-shaped hashes. Switches between weekly buckets (`DATE_PART('week', ...)`) and daily buckets (`DATE_PART('dow', ...)`) based on whether `week` was provided.
- `app/lib/musicbox_unwound.rb` — Standalone year-end "wrapped"-style report. Not wired into GraphQL; prints `Terminal::Table` output to STDOUT for ad-hoc/console use. Hardcodes the team name "Plug Dot DJ Expats" and iterates back through past years until it runs out of plays.
