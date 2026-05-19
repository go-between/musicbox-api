---
id: 9
kind: produce
verify: pass
---

## Changes
- Created `autopilot-support/index/features/password-reset/map.md` listing all six CSV-classified files grouped by layer (mutations, worker, specs).
- Created `autopilot-support/index/features/password-reset/patterns.md` covering Devise `:recoverable` token storage, `start_password_reset!` seam, `with_reset_password_token` lookup, the 6-hour `reset_password_within` window, the initiate -> worker `(user_id, raw_token)` handoff, the stable error-string contract, and the shared mailgun worker example.
- Created `autopilot-support/index/features/password-reset/boundaries.md` capturing extension points (delivery channels via sibling workers, token format via Devise overrides, window tuning via initializer), do-not-build rules (no Devise bypass, no enumeration, no token re-derivation in worker), and feature edges (User model and Doorkeeper access token issuance owned by user-authentication; mailgun shared example is cross-feature infra).

## Verify Result
- `test -s` on all three files: pass (no EMPTY output).
- CSV-basename presence check against `map.md`: pass (no MISSING output) — covered `password_reset_complete.rb`, `password_reset_initiate.rb`, `email_password_reset_worker.rb`, `password_reset_complete_spec.rb`, `password_reset_initiate_spec.rb`, `email_password_reset_worker_spec.rb`.
- Line-number leak grep (`:[0-9]+` excluding http): pass (no matches).

## Notes
- Confirmed `reset_password_within = 6.hours` in `config/initializers/devise.rb` matches the comment in `password_reset_complete_spec.rb` ("We use a six hour reset period"); referenced this in patterns without quoting the value as code.
- `User#start_password_reset!` (in `app/models/user.rb`) is the only app-owned wrapper around Devise's `set_reset_password_token`; flagged it as the extension seam in boundaries.
- The complete mutation issues a Doorkeeper access token on success via `access_token_for`; called this out as a cross-feature coupling to user-authentication rather than a password-reset concern.
