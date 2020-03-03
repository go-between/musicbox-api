# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Songs($query: String) {
        songs(query: $query) {
          id
        }
      }
    )
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  it "retrieves all of a user's songs" do
    s1 = create(:song)
    s2 = create(:song)
    s3 = create(:song)

    user.songs << s1
    user.songs << s2
    other_user.songs << s3

    graphql_request(query: query, user: user)

    song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
    expect(song_ids).to match_array([s1.id, s2.id])
  end

  it "retrieves all of a user's songs when search is empty" do
    s1 = create(:song)
    s2 = create(:song)
    s3 = create(:song)

    user.songs << s1
    user.songs << s2
    other_user.songs << s3

    [nil, ""].each do |term|
      graphql_request(query: query, user: user, variables: { query: term })

      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to match_array([s1.id, s2.id])
    end
  end

  it "retrieves only matching songs" do
    non_match = create(:song, name: "ballooba")
    s1 = create(:song, name: "floopadoop")
    s2 = create(:song, name: "LOOPABLARG")
    s3 = create(:song, name: "bling!!!LoOp")

    user.songs << non_match
    user.songs << s1
    user.songs << s2
    user.songs << s3

    %w[LOOP loop LoOp].each do |term|
      graphql_request(query: query, user: user, variables: { query: term })

      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to match_array([s1.id, s2.id, s3.id])
    end
  end
end
