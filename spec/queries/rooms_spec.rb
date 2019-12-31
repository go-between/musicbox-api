# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rooms Query', type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query {
        rooms {
          id
        }
      }
    )
  end

  let(:team) { create(:team) }
  let!(:room) { create(:room, team: team) }
  let!(:room2) { create(:room, team: team) }

  describe 'query' do
    it "returns a list of rooms for the user's active team" do
      other_team = create(:team)
      other_room = create(:room, team: other_team)

      user = create(:user, teams: [team], active_team: team)

      graphql_request(
        body: { query: query },
        user: user
      )

      room_ids = json_body.dig(:data, :rooms).map { |r| r[:id] }
      expect(room_ids).to match_array([room.id, room2.id])
    end

    it 'does not return rooms when user has no active team' do
      other_team = create(:team)
      other_room = create(:room, team: other_team)

      user = create(:user, teams: [team], active_team: nil)

      graphql_request(
        body: { query: query },
        user: user
      )

      expect(json_body.dig(:data, :rooms)).to be_empty
    end
  end
end
