# Step 2 — structures/modules.md

- id: 2
- kind: produce
- verify: pass

## Changes

- Created `autopilot-support/index/structures/modules.md` — index of non-MVC code: `app/lib` (service objects, errors, reporting), the `Selectors` namespace pattern and its GraphQL callers, the (empty) concerns directories, Sidekiq worker groupings (`broadcast_*`, `email_*`, `queue_management`), and `lib/tasks`.

## Verify Result

```
$ test -s autopilot-support/index/structures/modules.md && echo OK
OK

$ grep -cE '^#' autopilot-support/index/structures/modules.md
6

$ grep -c '\.rb' autopilot-support/index/structures/modules.md
9

$ grep -nE ':[0-9]+' autopilot-support/index/structures/modules.md
(no output; exit 1)
```

All four checks pass: file non-empty, 6 headings (>=4), 9 `.rb` path references (>0), zero `:line-number` patterns.

## Notes

- `app/concerns/` does not exist in this repo; `app/models/concerns/` and `app/controllers/concerns/` contain only `.keep` files. Documented this as a finding rather than omitting the heading.
- `MusicboxUnwound` (console report) and `Unwound` (GraphQL-backing) are intentionally distinct classes with overlapping names — called this out explicitly.
- `app/lib/selectors.rb` is a one-line namespace declaration; the real selectors are the four classes under `app/lib/selectors/`. Wired up only from `app/graphql/types/query_type.rb`.
- All `broadcast_*` workers share an identical shape: execute an inline GraphQL query with auth override, then `broadcast_to` a channel. Listed the channel pairings inline so callers can map worker -> channel quickly.
- `email_*` workers bypass ActionMailer and POST directly to Mailgun's HTTP API — non-obvious enough to flag.
