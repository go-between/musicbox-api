# Work Session Prompt — bootstrap-index

You are executing one step of a multi-step work plan that bootstraps `autopilot-support/index/` for the musicbox-api repository.

## Instructions

1. Read the progress tracker at `docs/work/bootstrap-index/progress.json`
2. Read the `execution_mode` field to understand how this work is being run
3. Find the first step where `done` is `false` and all `depends_on` steps are `done: true`
   - If no step is ready (all undone steps have unmet dependencies), stop and report
4. Read all files listed in that step's `files` array for context
5. Perform the work described in the step's `description` and `deliverable`:
   - For `produce` and `modify` steps, make the changes within the `changes` array
   - For `audit` steps, inspect the listed files and write your findings to `output_file`
   - For `verify` steps, run the verification described in `verify` and report
   - For `integrate` steps, wire together the pieces from prior steps
6. Run the step's `verify` check
   - If the verify check **passes**, continue to step 7
   - If the verify check **fails**, do not mark the step done — write a work-log entry with `Verify: fail`, document what failed, and stop. Let the human decide whether to retry, revise the plan, or fix manually.
7. Write a brief work-log entry to `output_file`:
   - Header: step name, id, kind, verify status (`pass` or `fail`)
   - `## Changes` section listing every file created or modified with one-line summaries
   - `## Verify Result` section showing concrete evidence (command output, criterion check)
   - `## Notes` section for surprises, follow-ups, or anything the reviewer should know (omit if nothing notable)
8. Mark the step `done: true` in `progress.json` (only if verify passed)
9. Stop — do not proceed to the next step

## Index Conventions (read before any step)

The index lives at `autopilot-support/index/` and follows these rules — every step must obey them:

1. **Point to files, never duplicate code.** Reference paths like `app/models/room.rb`. Never paste code blocks or function bodies into the index.
2. **No line numbers.** Files churn; line numbers rot. Reference symbols by name (`Room#activate!`), not location.
3. **Only non-obvious information.** If a reader can learn it in 30 seconds by reading the file, don't write it in the index. The index records *why*, *where to look*, and *what's surprising* — not *what the code says*.
4. **Manifest is the entry point.** `autopilot-support/index/CLAUDE.md` lists every structure and feature file. Any file you create must be listed there (the integrate step handles final reconciliation).
5. **Three-file feature convention.** Each `features/{slug}/` directory contains exactly three files:
   - `map.md` — what files comprise this feature and what each does (one line per file, points to path)
   - `patterns.md` — non-obvious conventions, idioms, and abstractions used by this feature
   - `boundaries.md` — extension points, "do not build" items, and where this feature ends / another begins
6. **Use `feature_classification.csv` as the source of truth for feature scope.** Filter its rows by the `Feature` column to find which files belong to a feature. The CSV uses the label from the original classification (e.g., "Playlist Management"); slug mapping is in the step description.

## Important

- **Stay within the step's `changes` scope.** Do not modify files outside that list. If you discover the change scope is wrong, stop and report rather than expanding it.
- **Do not modify application code.** This work is read-only against `app/`, `lib/`, `db/`, `config/`, `spec/`, `docs/`, and the root `CLAUDE.md` (if any). Only writes to `autopilot-support/index/` are permitted (plus the work log under `docs/work/bootstrap-index/outputs/`).
- **If a listed file doesn't exist**, note it in the work log and check for likely alternatives before proceeding.
- **If you discover work that needs doing outside the step's scope**, add it to the `## Notes` section — don't silently absorb it.
- Each session is independent — future sessions won't share your context. The work log is the durable handoff.
- Check `depends_on` before executing — if a dependency isn't `done: true`, skip that step and look for one that's ready.

## After Completing the Step

After marking the step done, summarize what changed and what verified in 2-3 sentences.
