# Music Tagging — Boundaries

## Extension points
- New tag metadata (color, icon, description, ordering): add columns to the `tags` table and expose on `Types::TagType`. The validation surface is intentionally minimal — extend on `Tag` and the mutation will keep working without changes if the field is optional.
- New tag-side queries (list a user's tags, filter library records by tag) belong on `current_user.tags` / `tag.library_records` — the associations are already in place; the missing piece is a query field, not a model change.
- Bulk operations beyond add/remove (rename, merge, delete) can be added as sibling mutations next to `tag_create.rb` / `tag_toggle.rb`. Keep ownership enforcement via `current_user.tags.find_by(...)` — that pattern is the de facto authorization check for tag-scoped mutations.
- DB-level uniqueness on `[tag_id, library_record_id]` lets new callers safely use `insert_all` / `upsert_all` without app-level dedup. Preserve that index when adding columns to the join.

## Do-not-build
- Don't tag `Song` directly. The previous schema (`tags_songs`) was migrated away from for a reason: tagging is per-user, and songs are global. Route any "tag this track" intent through the user's `LibraryRecord` — create the library record first if needed (see **music-library**).
- Don't introduce global, team-scoped, or shared tags through this feature. The data model has no notion of tag visibility; bolting it on with a nullable `user_id` or a `team_id` column will silently break `TagToggle`'s `current_user.tags.find_by(...)` authorization. Sharing requires a real design pass.
- Don't add `validates_uniqueness_of` on `TagLibraryRecord`. The unique index already enforces it and is the canonical check; an AR validation would race and add no safety.
- Don't add AR callbacks to `TagLibraryRecord` expecting them to fire from `TagToggle`. The mutation uses `insert_all`/`delete_all` to stay cheap; any callback-driven side-effect needs to move into the mutation itself.
- Don't make `TagToggle` distinguish "tag not found" from "tag belongs to another user." The collapsed error is intentional non-enumeration.

## Where tagging ends
- `LibraryRecord` (the user-song join), its lifecycle, and its association back to `Tag` belong to **music-library**. This feature owns the tag side of the join only.
- `Song` (the YouTube-backed track) belongs to **songs**. Tagging never references songs directly at runtime; only the 2020-05-13 migration touches `song_id` and only to backfill.
- Tag-driven filtering, fuzzy tag search, or tag autocomplete belong to **search** (or a future feature) — `TagType` exposes nothing query-shaped today.
- The `User` and `current_user` plumbing comes from **user-authentication**; tagging consumes `current_user` but does not own it.
