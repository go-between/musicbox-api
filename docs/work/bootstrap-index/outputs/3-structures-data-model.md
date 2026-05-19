# Step 3 — structures/data-model.md

- id: 3
- kind: produce
- verify: pass

## Changes

- Created `autopilot-support/index/structures/data-model.md` — points to `db/structure.sql` and every model in `app/models/*.rb`, capturing relationships, enums, generated columns, search scopes, the recommendation-flow source filter, the `user_rotation` array, and the playback state on `Room`.

## Verify Result

```
$ test -s autopilot-support/index/structures/data-model.md && echo OK
OK

$ for f in app/models/*.rb; do
    base=$(basename "$f" .rb)
    [ "$base" = "application_record" ] && continue
    name_underscored=$(echo "$base")
    name_titlecase=$(echo "$base" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS='')
    grep -qi "$name_underscored\|$name_titlecase" autopilot-support/index/structures/data-model.md || echo "MISSING: $base"
  done
(no output — every model referenced)

$ grep -nE ':[0-9]+' autopilot-support/index/structures/data-model.md
(no output — no line numbers in the doc)
```

## Notes

- `app/models/concerns/` exists as an empty directory; called out explicitly in the doc's "Notes and gotchas" section.
- Doorkeeper and Devise tables (`oauth_*`, Devise columns on `users`) have no Rails models in `app/models/`; mentioned in the gotchas so future readers don't go hunting.
- The doc cites the recent commit `8a9a086` ("Switch to structure.sql to preserve PostgreSQL functions") as context for why `db/structure.sql` is authoritative.
