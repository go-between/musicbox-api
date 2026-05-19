# Music Statistics — Patterns

## "Unwound" naming
- The feature is named after Spotify-Wrapped-style "unwinding" of play history — buckets of plays/approvals rolled out across a year or week. The GraphQL type, the service object, and the console script all share the prefix; treat `Unwound*` as a stable namespace, not a coincidence.
- `MusicboxUnwound` and `Unwound` are not a wrapper pair — they are two separate implementations of the same idea (year-end rollups). `Unwound` is the live GraphQL-backed version with full parameterization (year/team/user/week/song). `MusicboxUnwound` predates it as a CLI/console-only sketch, hardcodes the team, and emits `Terminal::Table` text. New aggregations belong in `Unwound`; treat `MusicboxUnwound` as legacy/example code.

## Plays vs listens — two data sources
- `RoomPlaylistRecord` is the source of truth for "a song was played in a room" (the DJ event). Anything counting *plays* (`team_plays`, `top_plays`, `top_plays_over_time`, `song_plays*`) groups over `room_playlist_records`.
- `RecordListen` (see `app/models/record_listen.rb`) is one row per listener-per-play and carries the `approval` integer. Anything counting *approvals* (`team_approvals`, `top_approvals`) groups over `record_listens`. Both are filtered to the same period and the same team's users.
- `team_approvals` is the only field that joins both sources in one method: it computes approvals *given* from `RecordListen` and approvals *received* by joining `RoomPlaylistRecord` to its `record_listens` (excluding self-approvals via `room_playlist_records.user_id != record_listens.user_id`).

## Period and bucket selection
- `Unwound#period_start`/`#period_end` collapse the year-vs-week mode behind one query interface. If `week` is present, the period is one ISO week (`beginning_of_week`..`end_of_week`); otherwise it's a full year.
- Bucketing inside `plays_over_time` switches on the same `week` arg: year mode emits 1..`period_end.cweek` rows labeled by ISO week number; week mode emits 0..6 rows labeled by day-of-week. The empty-bucket fill (zero-filling missing weeks/days) is intentional so the client sees a contiguous series.
- `start_day` walks forward day-by-day from Jan 1 until it lands in ISO week 1 — needed because Jan 1 is not always in cweek 1 (leap-year/weekday drift). Don't replace this with `Date#cweek` arithmetic without understanding that edge case.

## Result-row shape overloading
- Every list field returns `UnwoundCount` rows (`{ label, count, length }`), but the meaning of `length` varies: it's `sum(songs.duration_in_seconds)` for `team_plays`/`song_plays`, `approval_received` for `team_approvals`, and a literal `0` (placeholder) for `top_plays`/`top_approvals`/`plays_over_time` rows. Don't assume `length` is duration without checking the producing method.
- `label` is similarly polymorphic: user name for `team_*`, song name for `top_*` and `song_*`, and a week/day index string for the inner `plays_over_time` rows.

## Outlier filter
- Both `Unwound` and `MusicboxUnwound` exclude songs with `duration_in_seconds >= 90 minutes` via `invalid_songs`. This is the project's standing filter for "this isn't a song, it's a mix/podcast" — apply the same filter to any new aggregation here.

## User scoping
- `Unwound#users` defaults to the whole team, but collapses to a single-user array when `user_id` is provided. Every aggregation uses `where(user: users)` so the same code path serves both team-wide and per-user reports.
