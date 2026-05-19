# User Invitations — Boundaries

## Where this feature ends

- **User identity belongs to `user-authentication`.** `Mutations::InvitationAccept` calls into Devise (`User.find_for_database_authentication`, `valid_for_authentication?`, `valid_password?`) and `Mutations::BaseMutation#access_token_for` (Doorkeeper). When the invite flow has an "auth question" — what counts as a valid password, how access tokens are minted, how `current_user` is resolved — that lives in the user-authentication feature, not here.
- **Team membership belongs to `teams`.** `invited_user.teams << invite.team` writes to the `teams_users` join managed by the teams feature. The locking strategy (`with_lock`) is local to this mutation, but the join model, its uniqueness rules, and the `active_team` concept are owned by teams.
- **Mailgun delivery mechanics are shared.** `EmailInvitationWorker` and `EmailPasswordResetWorker` are sibling implementations of the same Mailgun-direct-HTTP pattern. The `"a mailgun worker"` shared example in `spec/workers/email_worker_shared_examples.rb` is the contract; treat changes to the HTTP shape as a cross-feature concern.

## Extension points

- **New invitation states.** The `invitation_state` enum lives on `Invitation` and is the single place to add values like `expired` or `revoked`. Anything new needs a backing column value (string, not integer — the enum maps to strings), the enum entry, a transition trigger (probably a new mutation or a worker), and updates to `Mutations::InvitationCreate#ensure_complete_invite!`, which currently has explicit logic only for `accepted` and `pending`.
- **New delivery channels.** Replace or wrap `EmailInvitationWorker` enqueuing in `Mutations::InvitationCreate#send_invite!`. Keep the contract narrow: the worker takes an `invitation_id` and is responsible for everything else. Any new channel worker (SMS, Slack, etc.) should land on its own queue, not piggyback on `email_invitations`.
- **Token strategy.** `Invitation.token` is the one chokepoint for token generation. Swap implementations there; do not inline random-token code at call sites. The column is `uuid`, so changing format requires a migration.
- **Email payload shape.** `EmailInvitationWorker#request` builds the `h:X-Mailgun-Variables` JSON blob. Adding or renaming variables also requires updating the Mailgun-side `invitation` template, which is not in this repo — coordinate.

## Do not build

- **Do not reinvent token logic in callers.** `Mutations::InvitationCreate` calls `Invitation.token`. Do not call `SecureRandom.uuid` directly from mutations or workers — the model class method is the seam tests stub against.
- **Do not bypass the worker for delivery.** Even in synchronous paths, send via `EmailInvitationWorker.perform_async`. Tests use `have_enqueued_sidekiq_job` to assert the enqueue happened; direct sends would break that contract and skip Sidekiq retries on Mailgun failures.
- **Do not add a `before_create` token callback.** The current pattern is explicit assignment in the mutation. Adding a callback would make the existing specs' `expect(Invitation).to receive(:token)` stubs fragile and would mask the "already pending — reuse token" branch.
- **Do not add a uniqueness validation on `email + team`.** The idempotency is enforced by `find_or_initialize_by`, not by a DB constraint. Adding a uniqueness rule would turn the re-invite path into a validation failure rather than a silent reuse. If you need DB-level safety, prefer a partial unique index over a model validation.
- **Do not expire invitations from inside this feature.** There is currently no expiry concept. If one is needed, add it as a state transition driven by a clock job (the project uses `clockwork` / Sidekiq), not as a query-time check.
- **Do not return enumeration-leaking errors from `InvitationAccept`.** The current `"Invalid invitation"` error is the same for "no such email" and "no such token" — keep it that way, mirroring the password-reset feature's no-leak convention.
