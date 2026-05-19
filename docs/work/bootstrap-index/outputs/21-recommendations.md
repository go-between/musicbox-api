# Step 21 — features/recommendations

- id: 21
- kind: produce
- verify: pass

## Changes

Wrote three files under `autopilot-support/index/features/recommendations/`:

- `map.md` — every CSV basename for `Music Recommendation` listed with a one-line role, grouped by layer: GraphQL Mutations and Specs (no model layer because recommendations have none). Opens with the framing that recommendations are `LibraryRecord` rows in a specific `source` state, not a model. Calls out non-obvious facts: `RecommendationCreate` looks up song by `youtube_id` (not GraphQL `id`); the dedupe check refuses *any* existing `LibraryRecord` for `(song, recipient)` regardless of source; `RecommendationAccept` only matches pending rows belonging to `current_user`; the `recommendations(songId:)` outbox branch does not filter on `pending_recommendation`. Points to `app/graphql/types/query_type.rb` for the query field while noting it is registered by `structures/resources.md`, not owned by this feature.

- `patterns.md` — six pattern sections: (1) recommendations are `LibraryRecord` rows with `source` of `pending_recommendation`/`accepted_recommendation`, recipient on `user`, sender on `from_user`; (2) "send" is `create!`, "accept" is a one-field `update!` — no separate model, no decline mutation today; (3) sender-side dedupe is row-presence, not source-equality (spec uses `source: ""` to assert), and song lookup is by `youtube_id`; (4) the recipient inbox is invisible through `User#library_records` because of the Arel `not_eq` + `or(IS NULL)` filter, so reads must hit `LibraryRecord` directly; (5) `QueryType#recommendations` has two asymmetric modes (inbox vs. outbox-by-song, latter with no source filter); (6) auth is implicit in scoping — create requires only recipient existence (no team/room scoping), accept's generic `"No recommendation"` error masks three distinct miss cases.

- `boundaries.md` — owns the two mutations, the semantic meaning of the two `source` enum values, the dedupe rule, and the `recommendations` query's filter semantics (even though the field itself is registered under `structures/resources.md`). Ends at music-library (model/table/enum declaration/association/selector/delete), songs (`Song` and `youtube_id` lookup), user-authentication (`User`/`current_user`), and the existing broadcast paths in real-time-playback/messages/teams (no recommendation channel or worker exists or should be added). Extension points: adding a decline source value, adding context columns on `LibraryRecord`, alternative acceptance triggers from sibling features, multi-recipient fan-out. Do-not-build: no `Recommendation` model/table, no recommendation channel/worker, no duplicate destroy mutation (use `LibraryRecordDelete`), no team/room auth wedged into create, no scattering of the source magic strings outside the three known reference sites. Schema invariants: `user`=recipient / `from_user`=sender direction, and `(song, recipient)` uniqueness enforced only at the application layer.

## Verify Result

- `test -s` for all three files — pass (none empty).
- CSV-basename coverage in `map.md` — pass (all 5 basenames present: `recommendation_accept.rb`, `recommendation_create.rb`, `recommendation_accept_spec.rb`, `recommendation_create_spec.rb`, `recommendations_spec.rb`; no `MISSING in map` output).
- `grep -nE ':[0-9]+' ... | grep -v http` — no matches (no line numbers leaked).

## Notes

- Index rules obeyed: pointed to files, no line numbers, no code fences, only non-obvious information (model/table/enum mechanics deferred to `features/music-library/`; song-resolution and `youtube_id` deferred to `features/songs/`; `current_user` mechanics deferred to `features/user-authentication/`).
- Cross-references: explicitly handed off `LibraryRecord` ownership to music-library, `Song` to songs, `User`/`current_user` to user-authentication; named the three reference sites for the `pending_recommendation`/`accepted_recommendation` strings (`app/models/library_record.rb`, `app/models/user.rb`, `app/graphql/types/query_type.rb`) and treated them as a closed set.
- Scope respected: no edits to `progress.json`, `app/`, `lib/`, `db/`, `config/`, `spec/`, or files outside `autopilot-support/index/features/recommendations/` and this work log.
