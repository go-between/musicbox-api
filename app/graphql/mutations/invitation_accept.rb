# frozen_string_literal: true

module Mutations
  class InvitationAccept < Mutations::BaseMutation
    class InvitationAcceptInputObject < Types::BaseInputObject
      argument :name, String, required: false
      argument :email, Types::EmailType, required: true
      argument :password, String, required: true
      argument :token, ID, required: true
    end

    argument :invitation, InvitationAcceptInputObject, required: true
    field :access_token, ID, null: true
    field :errors, [ String ], null: true

    def ready?(**_args)
      true
    end

    def resolve(invitation:)
      invite = Invitation.find_by(email: invitation[:email], token: invitation[:token])
      return { errors: [ "Invalid invitation" ] } if invite.blank?

      invited_user = ensure_invited_user!(**invitation.to_h)
      return { errors: [ "Unable to authenticate user" ] } if invited_user.blank?

      finalize_invitation!(invite, invited_user)

      {
        access_token: access_token_for(invited_user.id),
        errors: []
      }
    end

    private

    def ensure_invited_user!(email:, password:, name: nil, **_kwargs)
      user = User.find_for_database_authentication(email: email)
      return create_user!(email: email, password: password, name: name) if user.blank?

      user if user.valid_for_authentication? { user.valid_password?(password) }
    end

    def create_user!(email:, password:, name:)
      user = User.new(email: email, name: name, password: password)
      return unless user.valid?

      user.save!
      user
    end

    def finalize_invitation!(invite, invited_user)
      invited_user.with_lock do
        invited_user.teams << invite.team unless invited_user.teams.exists?(id: invite.team.id)
      end

      invite.update!(invitation_state: :accepted)
    end
  end
end
