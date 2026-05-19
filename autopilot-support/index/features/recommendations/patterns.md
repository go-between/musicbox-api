# Music Recommendation — Patterns

## A recommendation is a `LibraryRecord` in a particular state

- There is no `Recommendation` model, table, or migration. Recommendations are `LibraryRecord` rows whose `source` enum (defined in `app/models/library_record.rb`) is `pending_recommendation` (just sent) or `accepted_recommendation` (recipient acknowledged). The recommender is carried on the same row in `from_user_id`.
- Creation puts the row on the *recipient's* library (`user: to_user`), not the sender's. The sender appears only as `from_user`. Read both `recommendation_create.rb` and `recommendation_create_spec.rb` together — the test's `expect(other_user.songs).not_to include(song)` is the canonical demonstration that "pending" lives on the recipient but is filtered out of their normal song reads.

## "Send" and "accept" are state writes on that row

- `RecommendationCreate` is `LibraryRecord.create!` with the pending source. There is no separate "outbox" record on the sender — the single row encodes both ends of the recommendation via `user` (recipient) and `from_user` (sender).
- `RecommendationAccept` is a one-field `update!` that flips `source` from `pending_recommendation` to `accepted_recommendation`. It does not create or destroy rows. Re-running it on an already-accepted row returns `"No recommendation"` because the lookup filters on the pending source.
- There is no decline / reject mutation. The closest equivalent today is `Mutations::LibraryRecordDelete` (owned by **music-library**), which destroys the row outright. If a soft reject is ever needed, add a new `source` enum value rather than a new model.

## Sender-side dedupe is by *any* existing LibraryRecord

- `recommendation_create.rb` refuses creation when `LibraryRecord.exists?(song: song, user: to_user)` regardless of source. That means a recipient who already saved, was historically promoted, or was previously recommended the song cannot receive a fresh recommendation. The "already has song" spec uses `source: ""` (empty string, not `nil`) to assert this — the check is row-presence, not source-equality.
- Songs are resolved by `youtube_id`, not the GraphQL `id`. The mutation argument is named `youtube_id` and the lookup is `Song.find_by(youtube_id: …)`. Clients that already hold the GraphQL `Song.id` must re-thread the youtube id.

## Recipient's inbox is hidden by the `User#library_records` association

- `User#library_records` in `app/models/user.rb` excludes `source = "pending_recommendation"` via an Arel `not_eq` plus an explicit `or(source IS NULL)` clause. Consequence: pending recs are invisible to anything that traverses `user.library_records` or `user.songs`, including the music-library selector and stats.
- Reads that *need* to see pending rows must query `LibraryRecord` directly. Both `RecommendationAccept` and the `recommendations` query field on `QueryType` do exactly that — they bypass the association on purpose.

## The `recommendations` query has two modes with different filters

- See `app/graphql/types/query_type.rb#recommendations`. With no `song_id`: returns `current_user`'s pending inbox (`user: current_user, source: "pending_recommendation"`). With `song_id`: returns rows where `from_user: current_user` for that song, with no source filter — accepted outbound recs are included. The two branches are not symmetric and that asymmetry is exercised by `spec/queries/recommendations_spec.rb`.
- The resolver builds its `includes` from GraphQL lookahead (`:song`, `:user`, `:from_user`) to avoid N+1s. Any new association on `LibraryRecordType` consumed by this query must be added to the lookahead branches there.

## Authorization is implicit in the scoping

- `RecommendationCreate` requires only that the recipient (`to_user`) exists; any authenticated user may send to any other user. There is no team/room scoping today.
- `RecommendationAccept` authorizes by including `user: current_user` in the `find_by`. A miss returns `"No recommendation"` — the same string is returned for "doesn't exist", "belongs to someone else", and "already accepted". The error is intentionally generic.
