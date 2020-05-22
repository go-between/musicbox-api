# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Search($query: String!) {
        search(query: $query) {
          __typename
          ... on LibraryRecord {
            id
          }
          ... on Song {
            id
          }
          ... on YoutubeResult {
            id
          }
        }
      }
    )
  end

  let(:user) { create(:user) }
  let(:library_song) { create(:song, name: "my-song") }
  let!(:library_record) { create(:library_record, song: library_song, user: user) }
  let!(:other_song) { create(:song, name: "other-song") }

  it "prefers to return library records if any exist" do
    graphql_request(query: query, user: user, variables: { query: "song" })

    expect(json_body.dig(:data, :search).size).to eq(1)
    expect(json_body.dig(:data, :search, 0, :__typename)).to eq("LibraryRecord")
    expect(json_body.dig(:data, :search, 0, :id)).to eq(library_record.id)
  end

  it "returns songs if no library records exist" do
    graphql_request(query: query, user: user, variables: { query: "other-song" })

    expect(json_body.dig(:data, :search).size).to eq(1)
    expect(json_body.dig(:data, :search, 0, :__typename)).to eq("Song")
    expect(json_body.dig(:data, :search, 0, :id)).to eq(other_song.id)
  end

  it "returns youtube results if no library records or other songs exist" do
    # This won't result in a network request as long as we only retrieve the 'id'
    # and no other properties in our graphql call
    result = Yt::Models::Video.new(id: "youtube-id")
    video_double = instance_double(Yt::Collections::Videos, where: [result])
    expect(Yt::Collections::Videos).to receive(:new).and_return(video_double)

    graphql_request(query: query, user: user, variables: { query: "entirely-outside-song" })

    expect(json_body.dig(:data, :search).size).to eq(1)
    expect(json_body.dig(:data, :search, 0, :__typename)).to eq("YoutubeResult")
    expect(json_body.dig(:data, :search, 0, :id)).to eq("youtube-id")
  end
end
