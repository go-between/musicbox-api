# frozen_string_literal: true

require "rails_helper"
require_relative "./email_worker_shared_examples"

RSpec.describe EmailInvitationWorker, type: :worker do
  let(:inviting_user) { create(:user, name: "Jorm Nightengale") }
  let(:team) { create(:team, name: "Tunnel Snakes") }
  let(:token) { SecureRandom.uuid }
  let(:invitation) do
    Invitation.create!(
      inviting_user: inviting_user,
      team: team,
      token: token,
      email: "a@a.a"
    )
  end

  it_behaves_like "a mailgun worker" do
    let(:arguments) do
      [invitation.id]
    end
    let(:payload) do
      {
        from: "Truman at Musicbox <truman@musicbox.fm>",
        to: "#{invitation.name} <#{invitation.email}>",
        subject: "Your Musicbox Invitation",
        template: "invitation",
        "h:X-Mailgun-Variables": JSON.generate(
          inviter_name: "Jorm Nightengale",
          team_name: "Tunnel Snakes",
          token: token,
          email: URI.encode_www_form_component("a@a.a")
        )
      }
    end
  end
end
