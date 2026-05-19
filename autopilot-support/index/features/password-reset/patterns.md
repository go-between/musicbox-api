# Password Reset — Patterns

## Devise-managed token state
- Token storage and lifecycle live on `User` via Devise `:recoverable` (see `app/models/user.rb`): `reset_password_token` and `reset_password_sent_at` columns are written by Devise, not by app code.
- Token generation is wrapped in `User#start_password_reset!`, which delegates to Devise's `set_reset_password_token` and returns the raw token (the DB stores a digest, not the raw value).
- Lookup in the complete mutation uses `User.with_reset_password_token(token)`, which is the Devise scope that handles the digest comparison — do not hand-roll token matching.

## Expiration window
- Reset window is configured in `config/initializers/devise.rb` as `reset_password_within = 6.hours`. The complete mutation enforces it through `user.reset_password_period_valid?`; the spec asserts this by aging `reset_password_sent_at` past the window.

## Initiate -> worker handoff
- `PasswordResetInitiate` generates the token synchronously, then hands `(user_id, raw_token)` to `EmailPasswordResetWorker.perform_async`. The token travels through the Sidekiq payload, so the worker does not re-read or regenerate it.
- The initiate mutation deliberately returns the same empty-errors response whether or not the email matches a user — preserving non-enumeration is part of the contract.

## Complete mutation contract
- On success, returns a Doorkeeper access token (auto-signs the user in) via the same `access_token_for` helper used by login flows; this couples password reset to the auth-token issuance path.
- Error strings are stable and asserted by spec: `"Invalid token"`, `"Expired token"`, `"Invalid new password"`. Changing them is a breaking change for the client.
- Password update goes through `user.reset_password(password, password)` (Devise), which both clears the reset token and runs password validations in one call.

## Email delivery pattern
- Worker follows the same Mailgun-template pattern as other email workers and is covered by `spec/workers/email_worker_shared_examples.rb` (`"a mailgun worker"`), which standardizes payload shape and HTTP behavior assertions across the email worker family.
- The Mailgun template name `password-reset` is owned in the Mailgun account, not in the repo; the worker only ships variables.
