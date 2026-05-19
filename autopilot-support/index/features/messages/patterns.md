# Message & Chat System — Patterns

## Shape of a Message
- A `Message` always belongs to a `Room` and a `User`. The `room_playlist_record` and `song` associations are optional — they reflect "what was playing when this was said," not message structure. `MessageCreate` snapshots them from `current_user.active_room.current_record` at send time, so a message stays attached to the song that was playing then, even after the room moves on.
- Pinning is a `pinned` boolean column on `messages`. Do not introduce a `PinnedMessage` model; see `boundaries.md`. The same row participates in both the chat stream and the pinned stream.

## Two channels, one model
- `MessageChannel` and `PinnedMessagesChannel` are intentionally separate empty subclasses of `ApplicationCable::Channel`. Clients subscribe to whichever stream they care about; pinned-message updates would otherwise clobber the chat feed with full-set rebroadcasts (the pinned worker sends the whole pinned set, not a delta).
- Both channels stream per-room via `broadcast_to(Room.find(room_id))`. Auth is inherited from `ApplicationCable::Connection` (see `features/user-authentication/`); the channel classes themselves carry no logic.

## Broadcast-via-GraphQL workers
- Both broadcast workers render their payload by re-executing a `MusicboxApiSchema.execute(...)` against a hard-coded GraphQL document with `context: { override_current_user: true }`. This is the convention across the codebase's broadcast workers: render through the GraphQL surface so on-the-wire shape matches a normal query response, and skip user auth via the `override_current_user` flag.
- `BroadcastPinnedMessagesWorker` is the documented reason `Query#pinned_messages` accepts an optional `room_id` and tolerates a missing `current_user` — the comment in `app/graphql/types/query_type.rb` calls this out explicitly ("we're calling this with a current_user and no room_id. Except the broadcast worker which is calling with the opposite"). Authenticated clients pass no `room_id` and the field resolves to their `active_room`; the worker passes `room_id` and no user. Do not "clean this up" without rewiring the worker.

## Pin mutation is fan-out-on-every-call
- `MessagePin` enqueues `BroadcastPinnedMessagesWorker` on every successful resolve, including the no-state-change noop cases (pin-when-already-pinned, unpin-when-already-unpinned). The pin spec asserts this explicitly. The pinned-messages channel is treated as eventually-consistent; rebroadcasting on noops is the chosen way to repair drifted clients.
- `MessagePin` only allows the message's own author to toggle the pin (`Message.find_by(user: current_user, id: ...)`). There is no admin or room-owner override.

## Selector composition + lookahead
- `Selectors::Messages` is the only sanctioned way to query messages. It is intentionally chainable (`for_room_id(...).in_date_range(...).when_pinned_to(...).messages`) and `messages` is the terminal `order(created_at: :asc)` call.
- `record_context(lookahead)` inspects the GraphQL `lookahead` to decide which of `:room`, `:room_playlist_record`, `:song`, `:user` to `includes`. Keeping new associations out of this map will cause N+1 on the GraphQL surface even if the data is technically reachable.
- The selector is built with `Message.arel_table` (`@arel`) only because the date-range comparisons use `arel[:created_at].lteq/gteq` to keep nil-aware filtering tidy; other comparisons use plain `where`.

## Active-room is the chat scope
- `Query#messages` returns `[]` when there is no `active_room` and otherwise hard-scopes to `current_user.active_room_id`. There is no way to fetch messages for a room you're not currently sitting in. Same constraint is baked into `MessageCreate` (refuses if `active_room_id` is blank).
- "Active room" is owned by the **user-authentication** / **rooms** features (`User#active_room`). The chat feature consumes it; it does not define it.

## Schema-level looseness
- `messages` has only `room_id` and `created_at` indexes, no FK constraints, no `null: false` constraints on `room_id`/`user_id`. Integrity is enforced at the Rails layer via the model's `belongs_to`. Bulk inserts that skip ActiveRecord will not be caught by the DB.
