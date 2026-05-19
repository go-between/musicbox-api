# Message & Chat System — Boundaries

## Extension points
- New message metadata (reactions, edited-at, soft delete, attachment refs) should be added as columns on `messages` plus a new field on `Types::MessageType` and, if relevant to either broadcast, threaded into the worker's GraphQL document. The broadcast payload is whatever the worker's query asks for — fields not requested there will not reach the client even if they exist on the model.
- New attachment-style associations (e.g. an uploaded media record) should attach to `Message` via a new optional `belongs_to`, follow the `song`/`room_playlist_record` pattern (nullable, snapshotted at create time in `MessageCreate#create_message!`), and be added to the `record_context` lookahead map in `Selectors::Messages` so they eager-load on demand.
- New pin metadata (who pinned, pinned_at, pin reason) should be added as columns on `messages` alongside `pinned`. `BroadcastPinnedMessagesWorker`'s GraphQL document and the pinned-messages spec are where to thread them in.
- New query slices (e.g. "messages by user", "messages since I last read", "search within a room") should be added as additional chainable methods on `Selectors::Messages`, not as standalone scopes on `Message` or inline `where`s in `QueryType`.
- New broadcast targets (e.g. typing indicators, read receipts) should follow the broadcast-via-GraphQL worker convention — re-execute a fixed query with `override_current_user: true` and `broadcast_to(Room.find(room_id))` — and live as a new channel/worker pair.

## Do-not-build
- Do not introduce a separate `PinnedMessage` model, a `pinned_messages` table, or a join table for pinning. Pinning is a column on `messages` by design, and the pinned channel reads from the same rows.
- Do not bypass the broadcast workers. Mutations enqueue, workers render via GraphQL, channels deliver. Calling `MessageChannel.broadcast_to` directly from a mutation or model callback skips the GraphQL-shaped payload contract that all current clients depend on.
- Do not query `Message` directly from `QueryType`. Go through `Selectors::Messages` so lookahead-driven `includes` keep working.
- Do not "fix" `Query#pinned_messages` to require either a `current_user` or a `room_id` exclusively — the asymmetry exists so `BroadcastPinnedMessagesWorker` can call it with `override_current_user: true`. Read the inline comment before refactoring.
- Do not add cross-room message visibility. Active-room scoping is a feature, not an oversight; `MessageCreate` and `Query#messages` both enforce it.
- Do not let non-authors toggle pins. `MessagePin` deliberately restricts `pinned` writes to the message's own user; admin/moderator overrides are not a feature here.
- Do not rely on DB-level integrity. The migrations don't define FKs or null constraints on `room_id`/`user_id`/`song_id` — model-layer `belongs_to` is the only enforcement.

## Where messages end
- `Room` ownership, `active_room` resolution, and per-room broadcasting infrastructure belong to **rooms** (`features/rooms/`). Messages reference rooms but do not own them.
- `Song` modeling and the `room_playlist_record` join belong to **songs** (`features/songs/`) and **playlist-management** (`features/playlist-management/`); messages snapshot these references at send time but neither creates nor mutates them.
- `User` identity, `active_room` assignment, and channel-level auth (`ApplicationCable::Connection`) belong to **user-authentication** (`features/user-authentication/`). The empty channel classes here inherit that auth wholesale.
- The broadcast-via-GraphQL worker convention and `MusicboxApiSchema.execute` plumbing are cross-feature infrastructure (see `structures/infrastructure.md` and the other `Broadcast*Worker` siblings). Changes to that pattern affect every channel-broadcasting feature, not just chat.
- Notification / unread-state semantics are not implemented anywhere in this feature; if added, they should live alongside `User` state (read cursors) and `Selectors::Messages` filters, not as a new sibling model under messages.
