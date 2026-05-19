# Music Tagging — Patterns

## Tags are user-scoped, not global or team-scoped
- A `Tag` `belongs_to :user`. There is no `team_id`, no shared/global flag, and no visibility model. Two users in the same team have independent tag namespaces — name collisions are allowed and meaningful (each user's `"chill"` is a different row).
- `TagCreate` always assigns `user: current_user`. `TagToggle` re-scopes through `current_user.tags.find_by(id: tag_id)` before doing any work, so authorization is enforced by the scope, not by a separate check. Passing another user's `tag_id` returns the same `"Tag must be present"` error as a missing id — by design, no leak between the two cases.

## Tags attach to LibraryRecords, not Songs
- The join lives between `Tag` and `LibraryRecord`. A user can only tag songs that are already in their library — tagging implicitly requires library membership.
- The original `tags_songs` table was renamed in place to `tags_library_records` (see the 2020-05-13 migration). `TagLibraryRecord` carries an explicit `self.table_name` because the Rails-default name for the class would be `tag_library_records` (singular-plural), not the actual `tags_library_records` (plural-plural).
- The migration backfills `library_record_id` via `LibraryRecord.find_by(user_id: tag.user_id, song_id: ...)` — confirming the invariant that a tag's owner and the joined library record's owner are the same user. Nothing in the runtime code re-asserts that invariant; it's structural.

## Uniqueness is a DB-level guarantee
- The unique index on `[tag_id, library_record_id]` is the source of truth — there is no AR `validates_uniqueness_of` and no `find_or_create_by` in `TagToggle`. `insert_all` would raise on a conflict, so callers (the client) are expected to send sane `add_ids`.
- `TagToggle` uses `insert_all` and `delete_all` — both skip callbacks and validations. If callbacks ever get added to `TagLibraryRecord` they will not fire here.

## Two-mutation split
- `TagCreate` only mints the tag; it never attaches it to a record. `TagToggle` never creates a tag; it only mutates joins. The client is expected to chain them when creating-and-applying in one user action.
- `TagToggle` takes both `addIds` and `removeIds` in a single call so the client can drive a multi-select toggle UI in one round trip; partial failures aren't modeled (the two arrays run sequentially with no transaction wrapper).
