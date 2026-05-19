# User Invitations — Map

Token-based invite flow: an authenticated user invites an email to their active team, an email goes out via Mailgun, the recipient accepts to either create a new user or attach to an existing one and join the team.

## Model

- `app/models/invitation.rb` — `Invitation` AR record. Holds `email`, `name`, `token`, `invitation_state`, and the inviter/team association. Defines `Invitation.token` (UUID generator) and the `invitation_state` enum.

## GraphQL

- `app/graphql/types/invitation_type.rb` — `Invitation` GraphQL type. Exposes `email`, `name`, `invitation_state`, `inviting_user`, `invited_user`, and `team`.
- `app/graphql/mutations/invitation_create.rb` — `Mutations::InvitationCreate`. Authenticated. `find_or_initialize_by(email, team)` idempotency, mints a token only when missing, enqueues `EmailInvitationWorker`.
- `app/graphql/mutations/invitation_accept.rb` — `Mutations::InvitationAccept`. Public (overrides `ready?`). Looks up by `(email, token)`, creates-or-authenticates the user, joins them to the team, flips state to `:accepted`, returns an access token.

(Read-side resolvers live in `app/graphql/types/query_type.rb` — `invitation(token:, email:)` and `invitations` — but that file is shared with every other feature and lives in `structures/resources.md`, not here.)

## Worker

- `app/workers/email_invitation_worker.rb` — Sidekiq worker on the `email_invitations` queue. POSTs to Mailgun's `mg.musicbox.fm/messages` endpoint using the `invitation` template; raises `EmailInvitationWorker::DeliveryError` on non-2xx.

## Migrations

- `db/migrate/20191231155941_create_invitations.rb` — initial table. `id: :uuid`, `token` indexed, `invited_by_id` is the inviter FK (note the column name diverges from the association name).
- `db/migrate/20200102170036_add_state_to_invitation.rb` — adds `invitation_state` string column (backs the enum).
- `db/migrate/20200209060935_add_invited_user_name_to_invitation.rb` — adds `name` column for the invitee's display name (used by the email template and the GraphQL type).

## Specs

- `spec/models/invitation_spec.rb` — relationship coverage (`inviting_user`, `invited_user` by email match, `team`), `Invitation.token` delegation to `SecureRandom`, and enum state assignment.
- `spec/mutations/invitation_create_spec.rb` — request specs covering idempotency (same email/team re-invite reuses token), separate-team uniqueness, no state reset on already-accepted, and the unauthenticated-rejection case.
- `spec/mutations/invitation_accept_spec.rb` — request specs covering new-user creation, existing-user team attachment (case-insensitive email match), duplicate-team no-op, invalid email/token, failed auth for an existing user, and weak-password rejection.
- `spec/queries/invitation_spec.rb` — request spec for the public `invitation(email:, token:)` query.
- `spec/workers/email_invitation_worker_spec.rb` — uses the `"a mailgun worker"` shared example to assert the Mailgun POST body.

## Notes on what is NOT here

- No factory exists for `Invitation` (`spec/factories/` has none); every spec builds invitations with `Invitation.create!` inline. Tracked as a known gap in `structures/testing.md`.
- No mailer ERB templates live in the repo — the email body is a server-side Mailgun template referenced by name (`invitation`).
