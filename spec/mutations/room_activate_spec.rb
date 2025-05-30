# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Activate", type: :request do
  include AuthHelper
  include GraphQLHelper
  include JsonHelper

  let(:team) { create(:team) }
  let(:current_user) { create(:user, teams: [ team ]) }
  let(:room) { create(:room, team: team) }

  describe "success" do
    it "adds the user to the room" do
      graphql_request(
        query: room_activate_mutation(room_id: room.id),
        user: current_user
      )

      data = json_body.dig(:data, :roomActivate)

      expect(data.dig(:room, :id)).to eq(room.id)
      expect(data[:errors]).to be_empty
      expect(current_user.reload.active_room).to eq(room)
    end

    it "activates that room's team for the user" do
      current_user.update!(active_team: nil)
      graphql_request(
        query: room_activate_mutation(room_id: room.id),
        user: current_user
      )

      expect(current_user.reload.active_team).to eq(team)
    end

    it "enqueues a broadcast room worker" do
      graphql_request(
        query: room_activate_mutation(room_id: room.id),
        user: current_user
      )
      expect(BroadcastTeamWorker).to have_enqueued_sidekiq_job(room.team_id)
    end
  end

  describe "error" do
    it "does not allow a user to join a nonexistant room" do
      current_user.update!(active_room: nil)
      graphql_request(
        query: room_activate_mutation(room_id: SecureRandom.uuid),
        user: current_user
      )
      data = json_body.dig(:data, :roomActivate)

      expect(data[:errors]).not_to be_empty
      expect(current_user.reload.active_room).to be_nil
    end

    it "does not allow a user to join a room from a team they are not on" do
      other_team = create(:team)
      room = create(:room, team: other_team)

      graphql_request(
        query: room_activate_mutation(room_id: room.id),
        user: current_user
      )
      data = json_body.dig(:data, :roomActivate)

      expect(data[:errors]).not_to be_empty
      expect(current_user.reload.active_room).to be_nil
    end
  end
end
