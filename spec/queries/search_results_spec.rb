# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Songs Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Search {
        search {
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

  it "may return a library result, a song, or a youtube result" do
    library_record = create(:library_record)
    song = create(:song)
    # This won't result in a network request as long as we only retrieve the 'id'
    # and no other properties in our graphql call
    youtube_result = Yt::Models::Video.new(id: "test")

    results_double = instance_double(
      "Selectors::SearchResults",
      search: [library_record, song, youtube_result]
    )
    expect(Selectors::SearchResults).to receive(:new).and_return(results_double)

    graphql_request(query: query, user: user)
    library_record_result = json_body.dig(:data, :search).find { |r| r[:id] == library_record.id }
    expect(library_record_result[:__typename]).to eq("LibraryRecord")

    song_result = json_body.dig(:data, :search).find { |r| r[:id] == song.id }
    expect(song_result[:__typename]).to eq("Song")

    youtube_result = json_body.dig(:data, :search).find { |r| r[:id] == youtube_result.id }
    expect(youtube_result[:__typename]).to eq("YoutubeResult")
  end
end
