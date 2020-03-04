# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tag Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation TagCreate($name: String!) {
        tagCreate(input:{
          name: $name
        }) {
          tag {
            id
            name
            user {
              id
            }
            songs {
              id
            }
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }

  describe "#create" do
    it "creates a tag" do
      graphql_request(
        query: query,
        variables: { name: "Jam City" },
        user: current_user
      )
      data = json_body.dig(:data, :tagCreate, :tag)

      expect(Tag.exists?(id: data[:id])).to eq(true)
      expect(data[:name]).to eq("Jam City")
      expect(data.dig(:user, :id)).to eq(current_user.id)
      expect(data[:songs]).to be_empty
    end
  end

  context "when missing required attributes" do
    it "fails to persist when name is not specified" do
      expect do
        graphql_request(
          query: query,
          variables: { name: "" },
          user: current_user
        )
      end.not_to change(Tag, :count)

      data = json_body.dig(:data, :tagCreate)

      expect(data[:tag]).to be_nil
      expect(data[:errors]).to match_array([include("Name can't be blank")])
    end
  end
end
