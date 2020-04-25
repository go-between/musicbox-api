# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommendations Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Recommendations {
        recommendations {
          id
          source
          song {
            name
          }
          fromUser {
            name
          }
        }
      }
    )
  end

  let(:current_user) { create(:user) }
  let(:recommending_user1) { create(:user, name: "Jorm") }
  let(:recommending_user2) { create(:user, name: "Flawn") }

  it "retrieves all pending recommendations" do
    song1 = create(:song, name: "M83 - Outro")
    song2 = create(:song, name: "Indian Summer")
    song3 = create(:song, name: "Gloryhammer - Siege of Dunkeld")

    recommendation1 = UserLibraryRecord.create!(
      user: current_user,
      from_user: recommending_user1,
      song: song1,
      source: "pending_recommendation"
    )
    recommendation2 = UserLibraryRecord.create!(
      user: current_user,
      from_user: recommending_user2,
      song: song2,
      source: "pending_recommendation"
    )
    # already accepted
    UserLibraryRecord.create!(
      user: current_user,
      from_user: recommending_user1,
      song: song3,
      source: "accepted_recommendation"
    )
    # From me to someone else
    UserLibraryRecord.create!(
      user: recommending_user1,
      from_user: current_user,
      song: song3,
      source: "pending_recommendation"
    )

    graphql_request(
      query: query,
      user: current_user
    )

    recommendations = json_body.dig(:data, :recommendations)
    expect(recommendations.size).to eq(2)

    m83_recommendation = recommendations.find { |r| r[:id] == recommendation1.id }
    expect(m83_recommendation.dig(:song, :name)).to eq("M83 - Outro")
    expect(m83_recommendation.dig(:fromUser, :name)).to eq("Jorm")

    summmer_recommendation = recommendations.find { |r| r[:id] == recommendation2.id }
    expect(summmer_recommendation.dig(:song, :name)).to eq("Indian Summer")
    expect(summmer_recommendation.dig(:fromUser, :name)).to eq("Flawn")
  end
end
