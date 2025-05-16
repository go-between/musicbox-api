# frozen_string_literal: true

require "rails_helper"
require_relative "./email_worker_shared_examples"

RSpec.describe EmailPasswordResetWorker, type: :worker do
  let(:user) { create(:user, name: "Jorm Nightengale") }
  let(:token) { SecureRandom.uuid }

  it_behaves_like "a mailgun worker" do
    let(:arguments) do
      [ user.id, token ]
    end
    let(:payload) do
      {
        from: "Truman at Musicbox <truman@musicbox.fm>",
        to: "#{user.name} <#{user.email}>",
        subject: "Musicbox Password Reset",
        template: "password-reset",
        "h:X-Mailgun-Variables": JSON.generate(
          name: user.name,
          token: token,
          email: URI.encode_www_form_component(user.email)
        )
      }
    end
  end
end
