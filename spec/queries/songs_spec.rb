# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Songs($query: String, $tagIds: [ID!]) {
        songs(query: $query, tagIds: $tagIds) {
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

  it "excludes songs that are pending recommendations" do
    s1 = create(:song)
    s2 = create(:song)
    UserLibraryRecord.create!(user: user, song: s1, source: "pending_recommendation")
    UserLibraryRecord.create!(user: user, song: s2)

    graphql_request(query: query, user: user)
    song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
    expect(song_ids).to match_array([s2.id])
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

  it "retrieves only matching songs by name" do
    non_match = create(:song, name: "ballooba")
    s1 = create(:song, name: "floopadoop")
    s2 = create(:song, name: "LOOPABLARG")
    s3 = create(:song, name: "bling!!!LoOp")

    user.update!(songs: [non_match, s1, s2, s3])

    %w[LOOP loop LoOp].each do |term|
      graphql_request(query: query, user: user, variables: { query: term })

      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to match_array([s1.id, s2.id, s3.id])
    end
  end

  it "retrives only matching songs by tag ids" do
    tag1 = create(:tag, user: user)
    tag2 = create(:tag, user: user)

    s1 = create(:song, tags: [tag1])
    s2 = create(:song, tags: [tag2])
    s3 = create(:song, tags: [tag1, tag2])
    create(:song, tags: [])

    user.update!(songs: [s1, s2, s3])

    graphql_request(query: query, user: user, variables: { tagIds: [tag1.id] })
    song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
    expect(song_ids).to match_array([s1.id, s3.id])

    graphql_request(query: query, user: user, variables: { tagIds: [tag2.id] })
    song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
    expect(song_ids).to match_array([s2.id, s3.id])

    graphql_request(query: query, user: user, variables: { tagIds: [tag1.id, tag2.id] })
    song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
    expect(song_ids).to match_array([s1.id, s2.id, s3.id])
  end

  it "retrieves only matching songs by name and tag" do
    tag1 = create(:tag, user: user)
    tag2 = create(:tag, user: user)

    s1 = create(:song, name: "blingblong", tags: [tag1])
    s2 = create(:song, name: "blingflong", tags: [tag2])
    s3 = create(:song, name: "blooperdoooper", tags: [tag2])

    user.update!(songs: [s1, s2, s3])

    graphql_request(query: query, user: user, variables: { query: "ing", tagIds: [tag2.id] })
    song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
    expect(song_ids).to match_array([s2.id])
  end
end
