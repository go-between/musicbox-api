# Music Recommendation — Boundaries

What this feature owns, where it ends, and what not to build inside it.

## What this feature owns

- The two mutations `Mutations::RecommendationCreate` and `Mutations::RecommendationAccept`.
- The semantic meaning of `LibraryRecord.source` values `pending_recommendation` and `accepted_recommendation`, and of the `from_user_id` column when those sources are set.
- The send-side dedupe rule ("recipient must not already have the song in any form") and the recipient-side authorization rule on accept.
- The shape and asymmetry of the `recommendations` query field (inbox vs. outbox-by-song) — see Patterns. The field is *registered* in `app/graphql/types/query_type.rb` (owned by the GraphQL surface in `structures/resources.md`), but the filter semantics are this feature's contract.

## Where this feature ends

- **Music library** owns the `LibraryRecord` model, its table, the `source` enum declaration, the `User#library_records` association (and its pending-rec filter), the selector, and `LibraryRecordDelete`. This feature only writes specific `source` values into rows that the library feature defines. Any new column on `library_records`, any change to the enum, or any change to the association-level filter is a music-library change.
- **Songs** owns the `Song` model and its `youtube_id` lookup. `RecommendationCreate` calling `Song.find_by(youtube_id:)` is a consumer of that interface — it does not own song resolution.
- **User authentication & management** owns `User` and `current_user`. The `from_user` and `user` associations on `LibraryRecord` resolve to `User` rows that this feature does not create, validate, or update.
- **Real-time playback / messages / teams broadcast workers** fan out via their own channels. There is no recommendation channel and no recommendation broadcast worker. If a recipient must see a new pending rec in real time, the existing `LibraryRecord`- and `User`-level broadcast paths in those features are the integration point — not new workers under this slug.

## Extension points

- **Adding a "decline" outcome** — add a new value to the `LibraryRecord.source` enum (in `app/models/library_record.rb`, owned by music-library) such as `declined_recommendation`, then add `RecommendationDecline` here that transitions `pending_recommendation` → `declined_recommendation`. Decide whether the `User#library_records` association should also exclude the new value; the existing pending-rec exclusion is the precedent.
- **Adding context fields to a recommendation** (e.g., a note, a timestamp, a rating) — add the column to `library_records` via a music-library migration, expose it on `Types::LibraryRecordType`, and add the corresponding `argument` to `RecommendationCreate` here. Keep the field on `LibraryRecord` — do not introduce a sidecar `recommendation_metadata` table.
- **Alternative acceptance flows** (auto-accept, bulk accept, accept-on-play) — add a new mutation here that performs the same `source` update; route the trigger from the relevant feature (e.g., `RecordListenCreate` in listening-history could auto-accept a pending rec when the recipient plays it). The state transition rule lives here even if the trigger lives elsewhere.
- **Notifications for new/accepted recommendations** — wire into the existing real-time-playback or messages broadcast paths rather than creating a recommendations channel. The recommendation lifecycle is too coarse to justify a dedicated channel; piggyback on the recipient's library/user broadcast.
- **Recipient-targeting beyond a single user id** — `recommend_to_user` is a single `ID`. To support multi-recipient sends, fan out at the mutation level into N `LibraryRecord.create!` calls inside a transaction; do not introduce a "recommendation group" model.

## Do not build here

- **A `Recommendation` model or `recommendations` table.** The whole feature is intentionally implemented as state on `LibraryRecord`. Migrating to a dedicated model would require splitting `from_user_id`, `tags`, and the music-library selector across two tables for no behavioral gain.
- **A recommendation-specific ActionCable channel or broadcast worker.** Recipient-facing updates ride on existing channels — see "Where this feature ends" above.
- **A reverse-direction lookup that returns "users who recommended *me* a song"** under a new mutation. That read already exists via the `recommendations(songId:)` query branch (outbox-by-song); generalize the resolver before adding a sibling.
- **Authorization beyond user-existence on create.** There is no "are you allowed to recommend to this user" check today (no team/room scoping). If product needs that, it belongs on the read or write side of teams/rooms, not as a side-rule wedged into `RecommendationCreate`.
- **Source-string magic strings outside this feature's two mutations.** The strings `"pending_recommendation"` and `"accepted_recommendation"` are also referenced from `app/models/user.rb` and `app/graphql/types/query_type.rb#recommendations`. Treat those three reference sites as the closed set; do not scatter the strings further. New consumers should query through the existing query field or selector.
- **A "remove pending rec" mutation that destroys the row.** `Mutations::LibraryRecordDelete` (music-library) already destroys library rows under `current_user`. A recipient can reject a pending rec today by calling that mutation. Do not duplicate the destroy path here.

## Schema invariants

- A pending or accepted recommendation row's `user` is always the *recipient*; `from_user` is always the *sender*. Flipping that convention in any new code path breaks both the inbox query and the `User#library_records` filter.
- The dedupe key on send is `(song, user)` across *all* sources. Two rows for the same `(song, recipient)` pair should never exist; the create mutation enforces this but there is no DB-level uniqueness index, so background scripts and direct `LibraryRecord.create!` calls must respect it manually.

## Test boundary

Specs for this feature live in `spec/mutations/recommendation_*_spec.rb` and `spec/queries/recommendations_spec.rb`. They reach across into `LibraryRecord` directly — that is intentional and is the canonical way to assert pending-state behavior, since the `User#library_records` association would hide the rows under test.
