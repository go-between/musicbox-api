# Step 1 — Scaffold index + manifest skeleton

- **id:** 1
- **kind:** produce
- **verify:** pass

## Changes

- `autopilot-support/index/CLAUDE.md` — new manifest. States index rules verbatim from prompt.md, lists 5 planned structure files with relative links, lists all 17 planned feature directories with their CSV `Feature` label and a one-line placeholder summary, and documents how to extend the index.
- `autopilot-support/index/structures/` — new empty directory; placeholder for structure files produced by steps 2–6.
- `autopilot-support/index/features/{slug}/` — new empty directories for all 17 features: user-authentication, user-invitations, password-reset, teams, rooms, playlist-management, queue-management, real-time-playback, messages, music-library, songs, listening-history, music-statistics, tagging, recommendations, search, youtube.
- `docs/work/bootstrap-index/outputs/` — created to hold work logs for this multi-step plan.

## Verify Result

```
manifest exists
structures dir exists
feature dir count:       17
```

Feature slug grep (all 17 slugs): no MISSING output.
Structure file grep (modules, data-model, resources, infrastructure, testing): no MISSING output.
`ls autopilot-support/index/features/` confirms 17 directories matching the planned slugs.

## Notes

- The CSV uses the path prefix `musicbox-api/...` for every entry. Subsequent feature steps that cross-check `map.md` against the CSV filter should account for the `musicbox-api/` prefix when comparing basenames.
- The CSV's `Feature` labels include a few classifications that don't map to any planned feature directory (e.g., "GraphQL API", "Application Configuration", "Background Job Processing", "Environment Configuration", "Error Tracking", "API Security", "Scheduled Jobs", "Real-time Communication"). These cross-cutting concerns are covered by the **structures/** files (resources, infrastructure, modules) rather than by feature directories — this matches the plan.
- The slug `playlist-management` maps to CSV label `Playlist Management`; `queue-management` to `Queue Management`; `real-time-playback` to `Real-time Music Playback`; `user-authentication` to `User Authentication & Management`; `user-invitations` to `User Invitation System`; `password-reset` to `Password Reset System`; `teams` to `Team Collaboration`; `rooms` to `Room Management`; `messages` to `Message & Chat System`; `music-library` to `User Music Library`; `songs` to `Song Library`; `listening-history` to `Music Listening History`; `music-statistics` to `Music Statistics`; `tagging` to `Music Tagging`; `recommendations` to `Music Recommendation`; `search` to `Search Functionality`; `youtube` to `YouTube Integration`. Subsequent steps must filter the CSV by these labels, not by the slugs.
