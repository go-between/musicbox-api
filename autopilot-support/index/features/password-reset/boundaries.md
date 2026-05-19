# Password Reset — Boundaries

## Extension points
- New delivery channels (SMS, in-app, alternate ESP) plug in by adding a sibling worker to `app/workers/email_password_reset_worker.rb` and dispatching from `PasswordResetInitiate#send_password_reset_email!`. Keep the `(user_id, raw_token)` handoff shape so the token never has to be regenerated.
- Token format changes (length, encoding, single-use semantics) should be made by overriding Devise's reset helpers on `User`, not by introducing parallel token columns. `User#start_password_reset!` is the seam.
- Reset window tuning is a one-line change in `config/initializers/devise.rb` (`reset_password_within`); the complete mutation and its spec pick it up automatically.
- New failure reasons should be added as additional string entries in the `errors` array on `PasswordResetComplete` to keep the response shape stable.

## Do-not-build
- Do not bypass Devise's reset infrastructure. No custom `reset_password_token` columns, no hand-rolled digest comparisons, no manual `reset_password_sent_at` writes outside Devise — `with_reset_password_token` and `reset_password_period_valid?` are the only sanctioned lookups/validators.
- Do not return different responses from `PasswordResetInitiate` based on whether the email exists. Account enumeration is intentionally blocked here.
- Do not move password validation logic into the mutation; rely on `user.reset_password(...)` so password policies stay centralized on the `User` model.
- Do not have the worker re-derive or re-issue tokens. The raw token only exists at initiate time; the worker is a pure carrier.

## Where password-reset ends
- The `User` model and its Devise configuration (database_authenticatable, recoverable, validatable) belong to **user-authentication**. This feature consumes Devise's recoverable surface but does not own it.
- Normal authenticated password changes (profile-driven updates) live with **user-authentication**, not here. This feature is strictly the forgot-password / out-of-session path.
- Access token issuance (`access_token_for`, Doorkeeper integration) is owned by **user-authentication**; the complete mutation calls into it but should not grow Doorkeeper knowledge of its own.
- The Mailgun HTTP plumbing pattern and `"a mailgun worker"` shared example are cross-feature infrastructure; changes there affect every transactional email worker, not just password reset.
