# Music Statistics — Boundaries

## Extension points
- New aggregation methods belong on `app/lib/unwound.rb`. The convention is: add a private `*_in_period` or grouped scope on `plays_in_period`/`record_listens_in_period`, expose a public method that returns `UnwoundCount`-shaped hashes, add the key to the `#call` hash, and add the matching field to `app/graphql/types/unwound_type.rb`. Field name and hash key must agree — the GraphQL layer relies on the hash shape, not on explicit resolvers.
- New time windows (e.g. month, quarter, custom range) plug in at `period_start`/`period_end`/`start_day` and the `plays_over_time` branch. Keep the year-vs-week branch closed under a single `week.present?` check — don't sprinkle period logic across aggregation methods.
- New bucket granularities (hour-of-day, day-of-month) should extend `plays_over_time` with a new branch and a new `DATE_PART` group. The contiguous zero-fill pattern (iterate the full bucket range, look up each bucket, default to zero) is the contract clients expect — preserve it.
- New filters (genre, tag, source room) belong as additional `.where` clauses inside `plays_in_period`/`record_listens_in_period` so every aggregation picks them up uniformly.
- For a new GraphQL argument, extend both the `field :unwound` argument list in `app/graphql/types/query_type.rb` and the `Unwound#initialize` signature; the resolver passes args through by keyword.

## Do-not-build
- Do not record new plays or listens inside this feature. Play creation is owned by **playlist-management** (`RoomPlaylistRecord`) and listen logging is owned by **listening-history** (`RecordListen`). Stats are strictly read-side.
- Do not add denormalized stat columns to `RecordListen`, `RoomPlaylistRecord`, `Song`, or `User` (e.g. `play_count`, `total_approval`). All totals here are computed on read; introducing cached counters would couple write-path features to this feature's aggregation shape.
- Do not bypass the `invalid_songs` (>= 90 min) filter. If a new aggregation legitimately needs different filtering, factor the filter into a method on `Unwound` rather than inlining a contradictory rule.
- Do not extend `app/lib/musicbox_unwound.rb` for new features. It is a frozen console-only artifact (hardcoded team name, STDOUT output, no GraphQL surface). New work goes in `Unwound`.
- Do not add resolvers to `UnwoundType`/`UnwoundCountType`/`UnwoundCountPerWeekType`. These types are pure data shapes whose values come from the `Unwound#call` hash; adding resolver logic would split the aggregation across two layers.
- Do not introduce a selector under `app/lib/selectors/` for stats. The existing selectors (`library_records`, `messages`, `room_playlist_records`, `search_results`) are chainable read APIs for feature-owned models; `Unwound` is a one-shot report builder and intentionally lives outside that pattern.

## Where music-statistics ends
- Raw play events (`RoomPlaylistRecord` creation/lifecycle, broadcasting plays) are owned by **playlist-management** / **real-time-playback**. This feature only reads from `room_playlist_records`.
- Raw approval/listen events (`RecordListen` creation, the approval mutation) are owned by **listening-history**. This feature only reads from `record_listens`.
- Song metadata (name, `duration_in_seconds`, YouTube linkage) is owned by **songs**. The duration-based outlier filter is a *consumer* of that field, not a definition of it.
- Team membership resolution (`team.users`, `User.find`) is owned by **teams** / **user-authentication**. `Unwound#users`/`#team` are thin lookups, not the source of truth.
- No mutations live here. If a future need for "snapshot this report" or "export this stats payload" appears, that mutation belongs in a new sibling feature (e.g. reports/exports), not under music-statistics.
