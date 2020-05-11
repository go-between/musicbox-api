# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Songs($query: String, $tagIds: [ID!], $order: Order) {
        songs(query: $query, tagIds: $tagIds, order: $order) {
          id
          tags {
            id
          }
          userLibraryRecords {
            id
            source
            fromUser {
              id
            }
          }
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

  describe "when retrieving associated tags" do
    it "only retrieves the user's tags" do
      other_user = create(:user)
      tag1 = create(:tag, user: user)
      tag2 = create(:tag, user: other_user)

      s1 = create(:song, name: "blingblong", tags: [tag1, tag2])
      user.update!(songs: [s1])
      graphql_request(query: query, user: user)

      expect(json_body.dig(:data, :songs).size).to eq(1)
      tag_ids = json_body.dig(:data, :songs, 0, :tags).map { |t| t[:id] }
      expect(tag_ids).to match_array([tag1.id])
    end
  end

  describe "when retrieving associated user library records" do
    let(:song1) { create(:song, created_at: 1.day.ago, name: "CCC") }
    let(:song2) { create(:song, created_at: 2.days.ago, name: "AAAA") }
    let(:other_user) { create(:user, name: "the other user") }

    it "only retrieves the user's own library records" do
      record1 = UserLibraryRecord.create!(user: user, song: song1, from_user: other_user, source: "saved_from_history")
      record2 = UserLibraryRecord.create!(user: user, song: song2)
      UserLibraryRecord.create!(user: other_user, song: song1)
      UserLibraryRecord.create!(user: other_user, song: song2)

      graphql_request(query: query, user: user)

      song1_resp = json_body.dig(:data, :songs).find { |s| s[:id] == song1.id }
      song2_resp = json_body.dig(:data, :songs).find { |s| s[:id] == song2.id }

      expect(song1_resp.dig(:userLibraryRecords).size).to eq(1)
      record1_resp = song1_resp.dig(:userLibraryRecords).first
      expect(record1_resp[:id]).to eq(record1.id)
      expect(record1_resp[:source]).to eq("saved_from_history")
      expect(record1_resp.dig(:fromUser, :id)).to eq(other_user.id)

      expect(song2_resp.dig(:userLibraryRecords).size).to eq(1)
      record2_resp = song2_resp.dig(:userLibraryRecords).first
      expect(record2_resp[:id]).to eq(record2.id)
      expect(record2_resp[:source]).to be_nil
      expect(record2_resp[:fromUser]).to be_nil
    end
  end

  describe "ordering" do
    let(:song1) { create(:song, created_at: 1.day.ago, name: "CCC") }
    let(:song2) { create(:song, created_at: 2.days.ago, name: "AAAA") }
    let(:song3) { create(:song, created_at: 3.day.ago, name: "BBBB") }

    it "returns songs in creation order by default" do
      user.update!(songs: [song1, song2, song3])

      graphql_request(query: query, user: user)
      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to eq([song3.id, song2.id, song1.id])
    end

    it "returns songs in reverse creation order" do
      user.update!(songs: [song1, song2, song3])

      graphql_request(query: query, user: user, variables: { order: { field: "createdAt", direction: "desc" } })
      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to eq([song1.id, song2.id, song3.id])
    end

    it "returns songs in name order" do
      user.update!(songs: [song1, song2, song3])

      graphql_request(query: query, user: user, variables: { order: { field: "name", direction: "asc" } })
      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to eq([song2.id, song3.id, song1.id])
    end

    it "returns songs in reverse name order" do
      user.update!(songs: [song1, song2, song3])

      graphql_request(query: query, user: user, variables: { order: { field: "name", direction: "desc" } })
      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }
      expect(song_ids).to eq([song1.id, song3.id, song2.id])
    end

    it "returns an empty array when field is invalid" do
      user.update!(songs: [song1, song2, song3])

      graphql_request(
        query: query,
        user: user,
        variables: { order: { field: "name; DROP TABLE songs", direction: "desc" } }
      )
      song_ids = json_body.dig(:data, :songs).map { |s| s[:id] }

      expect(song_ids).to eq([])
      expect(Song.all).to be_present
    end
  end
end
