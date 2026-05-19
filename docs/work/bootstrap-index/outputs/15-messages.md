# Step 15 — Messages feature index

- id: 15
- kind: produce
- feature: Message & Chat System
- target: `autopilot-support/index/features/messages/{map,patterns,boundaries}.md`

## Files produced
- `autopilot-support/index/features/messages/map.md`
- `autopilot-support/index/features/messages/patterns.md`
- `autopilot-support/index/features/messages/boundaries.md`

## Verify

```
for f in autopilot-support/index/features/messages/{map,patterns,boundaries}.md; do test -s "$f" || echo "EMPTY: $f"; done
awk -F',' '$2=="Message & Chat System"' feature_classification.csv | cut -d',' -f1 | while read p; do
  base=$(basename "$p")
  grep -q "$base" autopilot-support/index/features/messages/map.md || echo "MISSING in map: $base"
done
grep -rnE ':[0-9]+' autopilot-support/index/features/messages/ | grep -v 'http' | head
```

- non-empty check: pass
- basename presence in map: pass (all 20 CSV files)
- line-number leak check: pass (no `name:NN` references in the three files)

## Notes
- Pinning is a column on `messages`, not a separate model — recorded in patterns + boundaries as a do-not-build.
- `Query#pinned_messages` accepts an optional `room_id` because `BroadcastPinnedMessagesWorker` invokes it with no current_user; called out in patterns.
- `MessagePin` enqueues the broadcast worker on every successful resolve, including no-op pins/unpins (spec-asserted); recorded as the eventual-consistency repair pattern.
- The `messages` table has no FK constraints and only `room_id`/`created_at` indexes; recorded under schema-level looseness in patterns.
