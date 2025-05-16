# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Password Update", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation UserPasswordUpdate($password: String!, $newPassword: String!) {
        userPasswordUpdate(input:{
          password: $password,
          newPassword: $newPassword
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe "success" do
    it "allows a user to update their password" do
      current_user.update!(password: "soSecretPassword!")

      graphql_request(
        query: query,
        user: current_user,
        variables: {
          password: "soSecretPassword!",
          newPassword: "AnEvenBetterMoreSecretPassword!"
        }
      )
      data = json_body.dig(:data, :userPasswordUpdate)

      current_user.reload
      expect(data[:errors]).to be_empty
      expect(current_user.valid_password?("AnEvenBetterMoreSecretPassword!")).to be(true)
    end
  end

  describe "error" do
    it "does not update a user's password when the existing password is wrong" do
      current_user.update!(password: "soSecretPassword!")

      graphql_request(
        query: query,
        user: current_user,
        variables: {
          password: "WhatAmIEvenTyping???",
          newPassword: "AnEvenBetterMoreSecretPassword!"
        }
      )
      data = json_body.dig(:data, :userPasswordUpdate)

      current_user.reload
      expect(data[:errors]).to include("Invalid password")
      expect(current_user.valid_password?("soSecretPassword!")).to be(true)
    end

    it "does not update a user's password when the existing password is insecure" do
      current_user.update!(password: "soSecretPassword!")

      graphql_request(
        query: query,
        user: current_user,
        variables: {
          password: "soSecretPassword!",
          newPassword: "a!"
        }
      )
      data = json_body.dig(:data, :userPasswordUpdate)

      current_user.reload
      expect(data[:errors]).to include("Insecure password")
      expect(current_user.valid_password?("soSecretPassword!")).to be(true)
    end
  end
end
