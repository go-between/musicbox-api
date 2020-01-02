# frozen_string_literal: true

module Mutations
  class InvitationCreate < Mutations::BaseMutation
    argument :email, String, required: true
    field :errors, [String], null: true

    def resolve(email:)
      return { errors: ['Must be on an active team'] } unless current_user.active_team.present?

      invite = Invitation.find_or_initialize_by(
        email: email,
        team: current_user.active_team
      )
      ensure_complete_invite!(invite)

      if invite.save
        { errors: [] }
      else
        { errors: invite.errors }
      end
    end

    private

    def ensure_complete_invite!(invite)
      invite.token = Invitation.token if invite.token.blank?
      invite.inviting_user = current_user if invite.inviting_user.blank?
      invite.invitation_state = :pending unless invite.accepted?
    end
  end
end
