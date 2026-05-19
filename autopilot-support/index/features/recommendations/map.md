# Music Recommendation — Map

Recommendations are not their own model. Every file below operates on `LibraryRecord` with a `source` of `pending_recommendation` or `accepted_recommendation`. See `features/music-library/` for the underlying model and table.

## GraphQL Mutations

- `app/graphql/mutations/recommendation_create.rb` — Creates a `LibraryRecord` on the recipient's library with `source: "pending_recommendation"` and `from_user_id: current_user.id`. Resolves the song by `youtube_id` (not by song id) and refuses to create if the recipient already has any `LibraryRecord` for that song, pending or otherwise.
- `app/graphql/mutations/recommendation_accept.rb` — Flips the recipient's pending row to `accepted_recommendation` via `update!`. Scopes the lookup to `user: current_user, source: "pending_recommendation"` so only the recipient can accept, and only while pending.

The `recommendations` query field itself lives in `app/graphql/types/query_type.rb` (owned by the GraphQL surface in `structures/resources.md`); it is the read path for both mutations below but is not in the CSV scope of this feature.

## Specs

- `spec/mutations/recommendation_create_spec.rb` — Asserts the created row's `from_user_id` and `pending_recommendation` source, and the two "already has the song" refusals (saved record with empty-string source, and an existing pending row). Confirms the recipient's `user.songs` does *not* include the pending song (the `User#library_records` filter).
- `spec/mutations/recommendation_accept_spec.rb` — Single happy-path spec: source transitions to `accepted_recommendation`, `from_user` is preserved.
- `spec/queries/recommendations_spec.rb` — Documents the two modes of the `recommendations` query: with no `songId` it returns the current user's pending inbox; with `songId` it returns the recommendations *the current user has sent* for that song (note: it does not filter by `pending_recommendation` in that branch — accepted outbound recs are included).
