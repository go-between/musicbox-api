# Step 19 — music-statistics (produce)

- id: 19
- kind: produce
- feature slug: music-statistics
- CSV label: Music Statistics

## Outputs
- `autopilot-support/index/features/music-statistics/map.md`
- `autopilot-support/index/features/music-statistics/patterns.md`
- `autopilot-support/index/features/music-statistics/boundaries.md`

## CSV scope (5 files)
- `app/lib/musicbox_unwound.rb`
- `app/lib/unwound.rb`
- `app/graphql/types/unwound_count_per_week_type.rb`
- `app/graphql/types/unwound_count_type.rb`
- `app/graphql/types/unwound_type.rb`

## Verify
- Non-empty check: pass (all three files non-empty)
- Every CSV basename present in map.md: pass (5/5)
- No file:line references: pass (only prose hits like "1:1" — no actual line numbers)
- Three-file convention: pass
- No code blocks pasted into index: pass

## Notes
- `Unwound` is the live GraphQL-backed report; `MusicboxUnwound` is a separate, frozen, console-only sibling (hardcoded team, `Terminal::Table` output) — flagged in patterns.md and boundaries.md.
- Data sources split deliberately: `RoomPlaylistRecord` for plays, `RecordListen` for approvals. `team_approvals` joins both.
- `UnwoundCount.length` is overloaded (duration vs approval received vs zero placeholder) — called out in patterns.md.
- Boundaries explicitly point raw-play work at playlist-management / real-time-playback and raw-listen work at listening-history.

Result: pass.
