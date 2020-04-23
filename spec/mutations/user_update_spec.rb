# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Password Update", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation UserUpdate($user: UserUpdateInputObject!) {
        userUpdate(input:{
          user: $user
        }) {
          user {
            name
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe "success" do
    it "allows a user to update their name" do
      current_user.update!(name: "Flingaborg")

      graphql_request(
        query: query,
        user: current_user,
        variables: {
          user: {
            name: "Superman by Goldfinger"
          }
        }
      )
      data = json_body.dig(:data, :userUpdate)

      current_user.reload
      expect(data[:errors]).to be_empty
      expect(data.dig(:user, :name)).to eq("Superman by Goldfinger")
      expect(current_user.name).to eq("Superman by Goldfinger")
    end
  end

  describe "error" do
    it "returns an error if no attributes are specified" do
      graphql_request(
        query: query,
        user: current_user,
        variables: {
          user: {}
        }
      )
      data = json_body.dig(:data, :userUpdate)

      current_user.reload
      expect(data[:errors]).to include("Must specify at least one attribute")
    end
  end
end
