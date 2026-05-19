# Step 4 — structures/resources.md

- **id:** 4
- **kind:** produce
- **verify:** pass

## Changes

- `autopilot-support/index/structures/resources.md` — new file documenting the API surface. Sections:
  - **GraphQL endpoint** — `POST /api/v1/graphql` via `graphql_controller.rb`, with notes on `NotAuthenticatedError`-to-401 conversion, dev-only error handler, and the `ensure_hash` shim for `variables`. Calls out that there are no traditional REST controllers and no GraphQL subscriptions.
  - **Mutations** — overview of `Mutations::BaseMutation` behavior (auth-by-default via `ready?`, opt-out for public flows, `access_token_for` helper). Grouped by domain: Auth/account creation, Invitations, Password reset, Teams, Rooms, Playlist/queue, Messages, Library, Songs, Tagging, Recommendations, Listening. Every mutation file basename appears with a one-paragraph note on its non-obvious behavior.
  - **Query type** — top-level patterns: `confirm_current_user!` with `override_current_user` escape hatch, lookahead-driven `includes`, delegation to `Selectors::*` classes, public queries (`invitation`, `unwound`), and the special `pinned_messages` dual-mode resolver.
  - **Base types & helpers** — points to each `base_*.rb` (intentionally thin) and documents the custom scalars and input objects (`date_time_type`, `email_type`, `order_type`, `ordered_field_type`, `ordered_direction_type`, `search_result_type`) with the non-obvious coercion details.
  - **ActionCable channels** — describes the inheritance-based room-scope default in `application_cable/channel.rb`, then notes each channel's broadcast source. Calls out that `TeamChannel` overrides scope, `UsersChannel` is the only presence mechanism (overriding `unsubscribed`), and that empty channel bodies exist solely for the broadcast namespace.
  - **Routes** — covers Sidekiq dashboard mount (no auth), ActionCable mount, GraphiQL with its hard-coded local-token initializer, the GraphQL endpoint, and `use_doorkeeper`. Calls out the surprising fact that Devise is configured but not routed.
  - **Authorization model** — three layers: GraphQL resolver layer (`context[:current_user]`, `NotAuthenticatedError`), OAuth layer (Doorkeeper), ActionCable layer (WS query-string token, secondary room/team checks in `subscribed`). Notes the absence of policies, scopes, admin roles, and rate-limiting.

## Verify Result

```
test -s autopilot-support/index/structures/resources.md && echo OK
OK
--- mutation check ---
(no output: all 23 non-base mutation basenames present)
--- channel check ---
(no output: all 9 channel files present, including application_cable/connection.rb and application_cable/channel.rb)
--- line number check ---
(no output: exit 1 from grep — no line-number references anywhere in the doc)
```

## Notes

- The prompt instructed me to "note Devise" under Routes. The actual `config/routes.rb` does not include `devise_for` — Devise is only configured at the initializer/model level and is exercised through Doorkeeper's password grant and through `Mutations::TeamCreate` / `InvitationAccept` / `PasswordReset*`. I documented this as the non-obvious fact rather than inventing a route that doesn't exist.
- Selectors and workers are mentioned by name where they connect to GraphQL resolvers, but full documentation lives in `structures/modules.md` (step 3) and the per-feature `map.md` files (steps 5+). The resources doc deliberately stops at "this resolver delegates to `Selectors::Messages`" rather than expanding on the selector's internals.
- `MessageChannel`, `NowPlayingChannel`, `PinnedMessagesChannel`, `RecordListensChannel`, `RoomPlaylistChannel` are all empty subclasses. I noted this once (under `application_cable/channel.rb`) and then gave each its own bullet describing which worker broadcasts to it — without that mapping, the empty class files would read as inscrutable.
- `graphql_controller.rb` renders `head 401` without a JSON error body. This will surprise clients expecting GraphQL-shaped error responses; flagged in the doc.
