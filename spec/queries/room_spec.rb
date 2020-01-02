# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Room Query', type: :request do
  include AuthHelper
  include JsonHelper

  def query(room_id:)
    %(
      query {
        room(id: "#{room_id}") {
          users {
            id
          }
        }
      }
    )
  end

  let(:team) { create(:team) }
  let(:room) { create(:room, team: team) }

  describe 'query' do
    it 'returns the details of a room that the user may view' do
      user1 = create(:user, teams: [team])
      user2 = create(:user, teams: [team], active_room: room)

      graphql_request(
        query: query(room_id: room.id),
        user: user1
      )
      active_user_ids = json_body.dig(:data, :room, :users).map { |u| u[:id] }
      expect(active_user_ids).to match_array([user2.id])
    end

    it 'does not return details of a room that the user may not view' do
      create(:user, teams: [team], active_room: room)
      other_team = create(:team)
      user2 = create(:user, teams: [other_team])

      graphql_request(
        query: query(room_id: room.id),
        user: user2
      )
      expect(json_body.dig(:data, :room)).to be_nil
    end
  end
end
