# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query(name:)
    %(
      mutation {
        roomCreate(input:{
          name: "#{name}"
        }) {
          room {
            id
            name
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }

  describe "#create" do
    it "creates room" do
      authed_post(
        url: "/api/v1/graphql",
        body: {
          query: query(name: "Rush Fans")
        },
        user: current_user
      )
      data = json_body.dig(:data, :roomCreate)
      id = data.dig(:room, :id)

      room = Room.find(id)
      expect(room.name).to eq("Rush Fans")
      expect(data[:errors]).to be_blank
    end

    it "creates new room belonging to the current users active team" do
      team = Team.create!(owner: current_user)
      current_user.update!(active_team: team)
      authed_post(
        url: "/api/v1/graphql",
        body: {
          query: query(name: "Rush Fans")
        },
        user: current_user
      )
      data = json_body.dig(:data, :roomCreate)
      id = data.dig(:room, :id)

      room = Room.find(id)
      expect(room.team).to eq(team)
    end
  end

  context "when missing required attributes" do
    it "fails to persist user is not on an active team" do
      current_user.update!(active_team: nil)

      expect do
        authed_post(
          url: "/api/v1/graphql",
          body: {
            query: query(name: "A room")
          },
          user: current_user
        )
      end.not_to change(Room, :count)

      data = json_body.dig(:data, :roomCreate)

      expect(data[:room]).to be_nil
      expect(data[:errors]).to match_array([include("Team must exist")])
    end

    it "fails to persist when name is not specified" do
      expect do
        authed_post(
          url: "/api/v1/graphql",
          body: {
            query: query(name: nil)
          },
          user: current_user
        )
      end.not_to change(Room, :count)

      data = json_body.dig(:data, :roomCreate)

      expect(data[:room]).to be_nil
      expect(data[:errors]).to match_array([include("Name can't be blank")])
    end
  end
end
