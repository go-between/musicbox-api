# User Invitations — Patterns

## Token generation lives on the model class

`Invitation.token` is a class method, not a callback. Callers (`Mutations::InvitationCreate#ensure_complete_invite!`) explicitly assign `invite.token = Invitation.token` when the field is blank. This is why the model spec stubs `SecureRandom.uuid` against `described_class.token` and why `invitation_create_spec.rb` stubs `Invitation.token` directly — there is no `before_create` to mock around.

The `token` column is `uuid` (see the create migration) and is indexed. There is no uniqueness constraint, but the GraphQL query uses `(token, email)` as the lookup pair so collision-on-token alone would not cross-leak invites.

## Idempotent create via (email, team)

`Mutations::InvitationCreate` uses `find_or_initialize_by(email: email.downcase, team: current_user.active_team)`. Implications:

- Re-inviting the same address for the same team reuses the existing row and the existing token, but still re-enqueues the worker — so the existing recipient gets another email with the same link.
- The same email across different teams creates separate invitations, each with its own token (covered by the "allows a new invitation for a different team" spec).
- An already-`accepted` invitation is never reset back to `pending` — `ensure_complete_invite!` guards with `unless invite.accepted?`. The worker still re-enqueues regardless; nothing prevents resending the email for an accepted invite.
- Email is lowercased on write. The accept path does not lowercase its lookup, but downstream `User.find_for_database_authentication` is case-insensitive (Devise default).

## Email delivery is direct HTTP to Mailgun, not ActionMailer

`EmailInvitationWorker` does not use ActionMailer — it builds a `Net::HTTP::Post` to `https://api.mailgun.net/v3/mg.musicbox.fm/messages` and basic-auths with `ENV["MAILGUN_KEY"]`. The body is `set_form_data` with `template: "invitation"` plus `h:X-Mailgun-Variables` carrying `inviter_name`, `team_name`, `token`, and a URI-encoded `email`. Consequence: there is no `app/views/mailers/` for this email — the template lives in the Mailgun account.

Non-2xx responses raise `EmailInvitationWorker::DeliveryError`, which surfaces as a Sidekiq retry.

The shared spec example `"a mailgun worker"` is defined in `spec/workers/email_worker_shared_examples.rb` and is used by both this worker and `EmailPasswordResetWorker` — that file is the canonical place to assert "this worker posts the right Mailgun payload."

## `invited_user` is an email-keyed association, not a FK

`Invitation` belongs to `invited_user` via `foreign_key: :email, primary_key: :email, class_name: "User", optional: true`. There is no `invited_user_id` column. Implications:

- The GraphQL `Invitation.invitedUser` field lights up automatically the instant a `User` with that email exists, regardless of whether the invitation was ever accepted. The invitation spec exercises this: it creates the user *after* the invitation and the association still resolves.
- Email is the join key on both sides, so case differences would break the link. `User#email` is normalized by Devise; `Invitation#email` is lowercased on create by the mutation.

## `inviting_user` uses a column name that diverges from the association

`belongs_to :inviting_user, foreign_key: :invited_by_id, class_name: "User"`. The database column is `invited_by_id` (set in the original create migration); the Ruby association is `inviting_user`. Selectors and queries that hand-write SQL should use `invited_by_id`; everywhere else, use the association.

## Acceptance state machine

The `invitation_state` enum has exactly two values: `pending` and `accepted`. There is no `expired`, `revoked`, or `declined`. Lifecycle:

1. `Mutations::InvitationCreate` sets state to `:pending` (unless already accepted) when minting or re-using the row.
2. `Mutations::InvitationAccept` calls `update!(invitation_state: :accepted)` inside `finalize_invitation!`. The state flip is the *last* step — user creation and team join run first; if either fails the state stays `pending`. The team-membership step is wrapped in `invited_user.with_lock` to avoid duplicate `teams_users` rows under concurrent acceptances.
3. There is no expiry check anywhere — a pending invitation is valid forever until accepted.

## Public mutation, but enforced lookup

`InvitationAccept` overrides `ready?` to return `true`, so it runs without `context[:current_user]`. The "authorization" is structural: the resolver does `Invitation.find_by(email:, token:)` and returns `{ errors: ["Invalid invitation"] }` on miss. Both fields are required for the lookup, so possession of just one is not enough.

## Team linkage at accept time

The invitation already knows its `team` from creation. Acceptance does `invited_user.teams << invite.team` (the `teams_users` join is owned by the teams feature, not this one). The `unless invited_user.teams.exists?(id: invite.team.id)` guard makes duplicate accepts a no-op for membership purposes — but the state still flips to `:accepted` and an access token still mints, so the mutation is effectively idempotent for an already-on-team user.
