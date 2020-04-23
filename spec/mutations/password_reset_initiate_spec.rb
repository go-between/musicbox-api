# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Password Reset Initiate", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation PasswordResetInitiate($email: Email!) {
        passwordResetInitiate(input:{
          email: $email
        }) {
          errors
        }
      }
    )
  end

  describe "success" do
    it "enqueues a password reset email" do
      user = create(:user, email: "a@a.a")

      post(
        "/api/v1/graphql",
        params: { query: query, variables: { email: "a@a.a" } }
      )

      expect(json_body.dig(:data, :passwordResetInitiate, :errors)).to match_array([])
      expect(EmailPasswordResetWorker).to have_enqueued_sidekiq_job(user.id, anything)
    end
  end

  describe "error" do
    it "does nothing when email is not found" do
      post(
        "/api/v1/graphql",
        params: { query: query, variables: { email: "noemail@a.a" } }
      )

      expect(json_body.dig(:data, :passwordResetInitiate, :errors)).to match_array([])
      expect(EmailPasswordResetWorker).not_to have_enqueued_sidekiq_job
    end
  end
end
