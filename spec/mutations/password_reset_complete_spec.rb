# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Password Reset Complete", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation PasswordResetComplete($email: Email!, $password: String!, $token: String!) {
        passwordResetComplete(input:{
          email: $email,
          password: $password,
          token: $token
        }) {
          accessToken,
          errors
        }
      }
    )
  end

  describe "success" do
    it "resets the user's password and returns an access token" do
      user = create(:user, email: "a@a.a", password: "somethingIForgot!!!")
      token = user.start_password_reset!

      post(
        "/api/v1/graphql",
        params: {
          query: query,
          variables: {
            email: "a@a.a",
            password: "abigpassword!",
            token: token
          }
        }
      )

      user.reload
      expect(user.valid_password?("abigpassword!")).to eq(true)
      expect(user.reset_password_token).to be_blank

      token = Doorkeeper::AccessToken.find_by(token: json_body.dig(:data, :passwordResetComplete, :accessToken))
      expect(token.resource_owner_id).to eq(user.id)
    end
  end

  describe "error" do
    it "does not reset the user's password when token is invalid" do
      user = create(:user, email: "a@a.a", password: "somethingIForgot!!!")
      user.start_password_reset!

      post(
        "/api/v1/graphql",
        params: {
          query: query,
          variables: {
            email: "a@a.a",
            password: "abigpassword!",
            token: "jibbbbbbberish"
          }
        }
      )

      user.reload
      expect(user.valid_password?("somethingIForgot!!!")).to eq(true)
      expect(user.reset_password_token).not_to be_blank
      expect(json_body.dig(:data, :passwordResetComplete, :errors)).to include("Invalid token")
    end

    it "does not reset the user's password when email does not match" do
      user = create(:user, email: "a@a.a", password: "somethingIForgot!!!")
      token = user.start_password_reset!

      post(
        "/api/v1/graphql",
        params: {
          query: query,
          variables: {
            email: "b@b.b",
            password: "abigpassword!",
            token: token
          }
        }
      )

      user.reload
      expect(user.valid_password?("somethingIForgot!!!")).to eq(true)
      expect(user.reset_password_token).not_to be_blank
      expect(json_body.dig(:data, :passwordResetComplete, :errors)).to include("Invalid token")
    end

    it "does not reset the user's password when token was created too long ago" do
      user = create(:user, email: "a@a.a", password: "somethingIForgot!!!")
      token = user.start_password_reset!

      # We use a six hour reset period
      user.update!(reset_password_sent_at: 7.hours.ago)

      post(
        "/api/v1/graphql",
        params: {
          query: query,
          variables: {
            email: "a@a.a",
            password: "abigpassword!",
            token: token
          }
        }
      )

      user.reload
      expect(user.valid_password?("somethingIForgot!!!")).to eq(true)
      expect(user.reset_password_token).not_to be_blank
      expect(json_body.dig(:data, :passwordResetComplete, :errors)).to include("Expired token")
    end

    it "does not reset the user's password when the new password is too short" do
      user = create(:user, email: "a@a.a", password: "somethingIForgot!!!")
      token = user.start_password_reset!

      post(
        "/api/v1/graphql",
        params: {
          query: query,
          variables: {
            email: "a@a.a",
            password: "a!",
            token: token
          }
        }
      )

      user.reload
      expect(user.valid_password?("somethingIForgot!!!")).to eq(true)
      expect(user.reset_password_token).not_to be_blank
      expect(json_body.dig(:data, :passwordResetComplete, :errors)).to include("Invalid new password")
    end
  end
end
