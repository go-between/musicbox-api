# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search Query", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      query Search($query: String!) {
        search(query: $query) {
          __typename
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
  let!(:other_song) { create(:song, name: "other-song") }

  it "returns songs that do not exist in the user's library" do
    create(:library_record, song: library_song, user: user)

    graphql_request(query: query, user: user, variables: { query: "song" })

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
