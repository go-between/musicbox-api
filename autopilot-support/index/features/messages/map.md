# Message & Chat System — Map

## Model
- `app/models/message.rb` — chat record; `belongs_to :room` (required), `belongs_to :user` (required), and optional `room_playlist_record` and `song`. Pin state is the `pinned` boolean column on this same row — there is no separate model.

## GraphQL
- `app/graphql/types/message_type.rb` — exposes `id`, `message`, `pinned`, `createdAt`, plus the four associations. `room` and `user` are non-null; `song` and `roomPlaylistRecord` are nullable to allow messages sent outside a playing track.
- `app/graphql/mutations/message_create.rb` — sends a message in the caller's `active_room`; auto-stamps `room_playlist_record` and `song` from the room's `current_record`. Enqueues `BroadcastMessageWorker`. Refuses if the user has no active room.
- `app/graphql/mutations/message_pin.rb` — toggles `pinned` on a message owned by `current_user`; enqueues `BroadcastPinnedMessagesWorker` regardless of whether the value actually changed (the noop cases are intentional — see patterns). Returns the error string `"Message must belong to the current user"` when ownership fails.
- Query wiring lives in `app/graphql/types/query_type.rb` (`messages` and `pinned_messages` fields, both with `extras: [:lookahead]`); see patterns for why `pinned_messages` accepts an optional `room_id`.

## Selectors
- `app/lib/selectors/messages.rb` — chainable `Selectors::Messages` builder with `for_room_id`, `in_date_range(to:, from:)`, and `when_pinned_to(song_id:)`; `record_context` drives lookahead-aware `includes` so association columns are eager-loaded only when the GraphQL selection asks for them.

## Channels
- `app/channels/message_channel.rb` — empty subclass of `ApplicationCable::Channel`; auth/streaming is owned by `ApplicationCable::Connection` (see `features/user-authentication/`). Streams per-room, fed by `BroadcastMessageWorker`.
- `app/channels/pinned_messages_channel.rb` — second empty channel for the pinned-messages stream; co-exists with `MessageChannel` rather than reusing it.

## Workers
- `app/workers/broadcast_message_worker.rb` — Sidekiq worker on the `broadcast_message` queue; re-executes a fixed GraphQL document against `MusicboxApiSchema` with `override_current_user: true` and broadcasts the result to `MessageChannel.broadcast_to(Room.find(room_id))`. Used for "new message arrived" fan-out.
- `app/workers/broadcast_pinned_messages_worker.rb` — Sidekiq worker on the `broadcast_pinned_messages` queue; broadcasts the full pinned set for `(room_id, song_id)` to `PinnedMessagesChannel`. Note the worker passes `roomId` but the GraphQL document declares it as `ID` (nullable); the query exists to be reachable both from authenticated callers and from this worker (see patterns).

## Migrations
- `db/migrate/20200125023143_create_messages.rb` — original `messages` table; UUID primary key, only `room_id` and `created_at` get indexes. No FKs are defined at the DB level.
- `db/migrate/20200305230807_add_pinned_to_messages.rb` — adds the `pinned` boolean (default `false`) directly onto `messages`; pinning was always a column, never a separate table.
- `db/migrate/20200307232816_add_song_id_to_message.rb` — adds nullable `song_id` so messages can be associated with whatever was playing when they were sent. No index added.

## Specs
- `spec/factories/message.rb` — defaults `pinned: false`, `room` and `user` created, but `room_playlist_record` and `song` are `nil`; pass them explicitly when exercising the "pinned to a song" path.
- `spec/models/message_spec.rb` — pins down that all four belongs_to associations work and that `room_playlist_record` is genuinely optional.
- `spec/mutations/message_create_spec.rb` — covers the active-room success path, the `BroadcastMessageWorker` enqueue, and the no-active-room refusal.
- `spec/mutations/message_pin_spec.rb` — exercises all four pin/unpin combinations (including noops), and asserts the broadcast worker is enqueued for each, plus the cross-user failure path.
- `spec/queries/messages_spec.rb` — locks in `active_room` scoping, ascending `created_at` order, and `from`/`to` filtering semantics.
- `spec/queries/pinned_messages_spec.rb` — locks in scoping to `(room_id, song_id)` with `pinned: true` only.
- `spec/workers/broadcast_message_worker_spec.rb` — uses `have_broadcasted_to(room).from_channel(MessageChannel)` and asserts the GraphQL payload shape (camelCased fields, `iso8601` timestamps).
- `spec/workers/broadcast_pinned_messages_worker_spec.rb` — same broadcast pattern, asserts the full pinned set is sent and that unpinned messages are excluded.
