# Step 6 — structures/testing.md

- id: 6
- kind: produce
- verify: pass

## Changes

Wrote `autopilot-support/index/structures/testing.md`. Sections covered:

- Helper setup (`rails_helper.rb`, `spec_helper.rb`, DatabaseCleaner, support auto-load, Gemfile test gems).
- Factories — flat layout, per-file notes including `users.rb` plural-filename quirk and the `SecureRandom.uuid` email pattern, plus missing factories (Invitation, RecordListen, Recommendation).
- Support helpers — `AuthHelper` (real Doorkeeper tokens, no stubbing), `GraphQLHelper`, `JsonHelper` (asserts `response.successful?`).
- Integration tests — single `spec/integration/requests_spec.rb` walks three users through end-to-end playlist building with `Sidekiq::Testing.inline!`.
- Mutation specs — `type: :request` pattern, inline `query` heredocs, `have_enqueued_sidekiq_job` for side effects, error cases asserting `data[:errors]`.
- Query specs — same pattern as mutations; `let!` fixture graphs for ordering tests.
- Worker specs — `type: :worker`, direct `perform`, broadcast assertions, the `email_worker_shared_examples.rb` shared-examples convention for mailgun workers.
- Model specs — relationships only; no validation/callback/scope tests by convention.
- Lib specs — `RoomPlaylistGenerator` and `RoomQueuePoller` covered; `YoutubeClient`/`Unwound`/`MusicboxUnwound` not directly specced.

## Verify Result

- `test -s` — pass.
- Required terms `rspec`, `factor`, `integration`, `mutation`, `support` all present.
- `grep -nE ':[0-9]+'` — no matches (no line numbers leaked into the doc).

## Notes

- Index rules obeyed: pointed to files, no line numbers, no code fences, only non-obvious info (e.g., the `:not_change` matcher defined in `spec_helper.rb`, the `users.rb` plural-filename oddity, the `AuthHelper#graphql_request` default of `create(:user)` so omitting `user:` still authenticates).
- Did not modify `progress.json`, `app/`, `lib/`, `db/`, `config/`, or `spec/`.
