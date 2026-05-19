# Password Reset — Map

## GraphQL Mutations
- `app/graphql/mutations/password_reset_initiate.rb` — accepts email, looks up user, generates reset token via `User#start_password_reset!`, enqueues delivery worker. Returns empty errors even on unknown email (no enumeration).
- `app/graphql/mutations/password_reset_complete.rb` — accepts email + token + new password, validates token, checks Devise reset window, applies new password, returns a Doorkeeper access token on success.

## Workers
- `app/workers/email_password_reset_worker.rb` — Sidekiq worker on the `email_password_resets` queue; posts to Mailgun using the `password-reset` template with `name`, `token`, and url-encoded `email` template variables.

## Specs
- `spec/mutations/password_reset_initiate_spec.rb` — request-level coverage for enqueue on hit and silent no-op on unknown email.
- `spec/mutations/password_reset_complete_spec.rb` — success + four error cases (invalid token, mismatched email, expired token, weak password); documents the six-hour reset window.
- `spec/workers/email_password_reset_worker_spec.rb` — exercises the worker via the `a mailgun worker` shared example with the expected Mailgun payload.
