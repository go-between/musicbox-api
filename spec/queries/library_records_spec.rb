# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query LibraryRecords($query: String, $tagIds: [ID!], $order: Order) {
        libraryRecords(query: $query, tagIds: $tagIds, order: $order) {
          id
          source
          fromUser {
            id
          }
          song {
            id
          }
          tags {
            id
          }
          user {
            id
          }
        }
      }
    )
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  it "retrieves all of a user's library_records" do
    r1 = create(:library_record)
    r2 = create(:library_record)
    r3 = create(:library_record)

    user.library_records << r1
    user.library_records << r2
    other_user.library_records << r3

    graphql_request(query: query, user: user)

    library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
    expect(library_record_ids).to contain_exactly(r1.id, r2.id)
  end

  it "excludes library_records that are pending recommendations" do
    create(:library_record, user: user, source: "pending_recommendation")
    r2 = create(:library_record, user: user)

    graphql_request(query: query, user: user)
    library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
    expect(library_record_ids).to contain_exactly(r2.id)
  end

  it "retrieves all of a user's library_records when search is empty" do
    r1 = create(:library_record, user: user)
    r2 = create(:library_record, user: user)
    create(:library_record, user: other_user)

    [ nil, "" ].each do |term|
      graphql_request(query: query, user: user, variables: { query: term })

      library_record_ids = json_body.dig(:data, :libraryRecords).map { |s| s[:id] }
      expect(library_record_ids).to contain_exactly(r1.id, r2.id)
    end
  end

  it "retrieves only matching library_records by name" do
    non_match = create(:song, name: "ballooba")
    s1 = create(:song, name: "loopmaster")
    s2 = create(:song, name: "LOOPABLARG")
    s3 = create(:song, name: "bling!!!LoOp")

    create(:library_record, user: user, song: non_match)
    r1 = create(:library_record, user: user, song: s1)
    r2 = create(:library_record, user: user, song: s2)
    r3 = create(:library_record, user: user, song: s3)

    %w[LOOP loop LoOp].each do |term|
      graphql_request(query: query, user: user, variables: { query: term })

      library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
      expect(library_record_ids).to contain_exactly(r1.id, r2.id, r3.id)
    end
  end

  it "retrives only matching library_records by tag ids" do
    tag1 = create(:tag, user: user)
    tag2 = create(:tag, user: user)

    r1 = create(:library_record, user: user, tags: [ tag1 ])
    r2 = create(:library_record, user: user, tags: [ tag2 ])
    r3 = create(:library_record, user: user, tags: [ tag1, tag2 ])
    create(:library_record, user: user, tags: [])

    graphql_request(query: query, user: user, variables: { tagIds: [ tag1.id ] })
    library_record_ids = json_body.dig(:data, :libraryRecords).map { |s| s[:id] }
    expect(library_record_ids).to contain_exactly(r1.id, r3.id)

    graphql_request(query: query, user: user, variables: { tagIds: [ tag2.id ] })
    library_record_ids = json_body.dig(:data, :libraryRecords).map { |s| s[:id] }
    expect(library_record_ids).to contain_exactly(r2.id, r3.id)

    graphql_request(query: query, user: user, variables: { tagIds: [ tag1.id, tag2.id ] })
    library_record_ids = json_body.dig(:data, :libraryRecords).map { |s| s[:id] }
    expect(library_record_ids).to contain_exactly(r1.id, r2.id, r3.id)
  end

  it "retrieves only matching library_records by name and tag" do
    tag1 = create(:tag, user: user)
    tag2 = create(:tag, user: user)

    s1 = create(:song, name: "blingblong")
    s2 = create(:song, name: "blingflong")
    s3 = create(:song, name: "blooperdoooper")

    create(:library_record, song: s1, user: user, tags: [ tag1 ])
    r2 = create(:library_record, song: s2, user: user, tags: [ tag2 ])
    create(:library_record, song: s3, user: user, tags: [ tag2 ])

    graphql_request(query: query, user: user, variables: { query: "ing", tagIds: [ tag2.id ] })
    library_record_ids = json_body.dig(:data, :libraryRecords).map { |s| s[:id] }
    expect(library_record_ids).to contain_exactly(r2.id)
  end

  describe "when retrieving associated tags" do
    it "only retrieves the user's tags" do
      other_user = create(:user)
      song = create(:song)
      tag1 = create(:tag, user: user)
      tag2 = create(:tag, user: other_user)

      create(:library_record, song: song, user: user, tags: [ tag1 ])
      create(:library_record, song: song, user: other_user, tags: [ tag2 ])
      graphql_request(query: query, user: user)

      expect(json_body.dig(:data, :libraryRecords).size).to eq(1)
      tag_ids = json_body.dig(:data, :libraryRecords, 0, :tags).map { |t| t[:id] }
      expect(tag_ids).to contain_exactly(tag1.id)
    end
  end

  it "only retrieves the user's own library records" do
    record1 = create(:library_record, user: user)
    record2 = create(:library_record, user: user)
    create(:library_record, user: other_user)
    create(:library_record, user: other_user)

    graphql_request(query: query, user: user)
    records = json_body.dig(:data, :libraryRecords)

    expect(records.map { |r| r[:id] }).to contain_exactly(record1.id, record2.id)
    expect(records.map { |r| r.dig(:user, :id) }).to contain_exactly(user.id, user.id)
  end

  describe "ordering" do
    let(:song1) { create(:song, name: "CCC") }
    let(:song2) { create(:song, name: "AAAA") }
    let(:song3) { create(:song, name: "BBBB") }
    let!(:record1) { create(:library_record, user: user, song: song1, created_at: 1.day.ago) }
    let!(:record2) { create(:library_record, user: user, song: song2, created_at: 2.day.ago) }
    let!(:record3) { create(:library_record, user: user, song: song3, created_at: 3.day.ago) }

    it "returns library records in creation order by default" do
      graphql_request(query: query, user: user)
      library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
      expect(library_record_ids).to eq([ record3.id, record2.id, record1.id ])
    end

    it "returns library records in reverse creation order" do
      graphql_request(query: query, user: user, variables: { order: { field: "createdAt", direction: "desc" } })
      library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
      expect(library_record_ids).to eq([ record1.id, record2.id, record3.id ])
    end

    it "returns library recoreds in name order" do
      graphql_request(query: query, user: user, variables: { order: { field: "song.name", direction: "asc" } })
      library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
      expect(library_record_ids).to eq([ record2.id, record3.id, record1.id ])
    end

    it "returns library records in reverse name order" do
      graphql_request(query: query, user: user, variables: { order: { field: "song.name", direction: "desc" } })
      library_record_ids = json_body.dig(:data, :libraryRecords).map { |r| r[:id] }
      expect(library_record_ids).to eq([ record1.id, record3.id, record2.id ])
    end

    it "returns an empty array when field is invalid" do
      graphql_request(
        query: query,
        user: user,
        variables: { order: { field: "name; DROP TABLE library_records", direction: "desc" } }
      )
      library_record_ids = json_body.dig(:data, :libraryRecords).map { |s| s[:id] }

      expect(library_record_ids).to eq([])
      expect(LibraryRecord.all).to be_present
    end
  end
end
