# Step 24 — Integrate: finalize manifest + cross-ref check

- **id:** 24
- **kind:** integrate
- **verify:** pass

## Changes

- `autopilot-support/index/CLAUDE.md` — replaced the skeleton one-liners with refined summaries derived from each produced file's H1 + intro. Every structure file now has a concrete one-line description; every feature directory now surfaces its highest-value non-obvious detail (the kind of thing a reader would otherwise have to read three files to discover). Added an integrity-check note to the "How to extend this index" section so future contributors can re-run the four checks.

No other index files were modified — the four cross-ref checks already passed on first run against the work product of steps 2-23, so the integrate step had nothing to fix.

## Verify Result

```
=== (a) Every linked file exists ===
PASS

=== (b) Every produced .md is referenced by basename ===
PASS

=== (c) Path-like line-number refs ===
PASS

=== (d) Ruby code fences ===
PASS

=== Summary of index ===
structures:        5
features:         17
total md files (excl manifest):  56
```

Check (a): every `autopilot-support/index/**/*.md` path linked from `CLAUDE.md` exists on disk.

Check (b): every `.md` file under `autopilot-support/index/` (excluding `CLAUDE.md` itself) has its basename referenced in `CLAUDE.md` — `map.md`, `patterns.md`, `boundaries.md` are covered by the three-file convention rule; the five `structures/*.md` files are linked directly.

Check (c): `grep -rEn '\.rb:[0-9]+|\.sql:[0-9]+' autopilot-support/index/` returns nothing.

Check (d): `grep -rEn '```(ruby|rb)$' autopilot-support/index/` returns nothing.

Total: **56 markdown files** under the index (5 structure files + 17 features × 3 files), plus the manifest.

## Notes

- The integrate step's write scope (`autopilot-support/index/**/*.md`) was deliberately not exercised beyond `CLAUDE.md`. All 22 prior subagents enforced the verify checks per-file before declaring pass, which kept the cross-ref clean at the integrate boundary. If a future re-run produces dirty output (line-numbers, code fences), this step is the place to clean it up.
- The search feature's `boundaries.md` and `patterns.md` flag a live discrepancy: `Song.search` (3-tier tsvector + pg_trgm + ILIKE) is implemented on the model but `Selectors::SearchResults#from_all_songs` uses plain ILIKE only. Worth surfacing to the team as an obvious low-cost wiring fix rather than letting it sit in the boundaries file forever.
- The youtube feature's `patterns.md` notes `YoutubeClient` has no error handling, no retries, and is not wired to Airbrake despite the initializer being configured. Also a candidate for a small follow-up.
- The recommendations feature is implemented entirely as a state flag on `LibraryRecord` (no `Recommendation` model). The boundaries file explicitly documents this so future contributors don't accidentally introduce a parallel model.
- The plan defined "execution_mode: subagent". The coordinator fanned out steps 2-6 (5 parallel agents) followed by steps 7-23 (17 parallel agents), and ran step 24 inline. All 22 subagents declared verify-pass; the coordinator's cross-ref pass confirmed it.
