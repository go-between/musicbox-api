# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Song Create", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation SongCreate($youtubeId: ID!, $fromUserId: ID) {
        songCreate(input: {
          youtubeId: $youtubeId,
          fromUserId: $fromUserId
        }) {
          song {
            id
            description
            durationInSeconds
            license
            licensed
            name
            thumbnailUrl
            youtubeId
            youtubeTags
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe "#create" do
    context "when song does not exist" do
      it "creates song and associates with current user" do
        video = OpenStruct.new(
          duration: 1500,
          description: "a description",
          license: "youtube",
          licensed?: false,
          thumbnail_url: "https://i.ytimg.com/vi/bnVUHWCynig/default.jpg",
          title: "a title",
          tags: %w[dope chill beatz]
        )
        expect(Yt::Video).to receive(:new).with(id: "an-id").and_return(video)

        graphql_request(
          query: query,
          variables: { youtubeId: "an-id" },
          user: current_user
        )

        data = json_body.dig(:data, :songCreate)
        id = data.dig(:song, :id)

        song = Song.find(id)
        expect(song.name).to eq("a title")
        expect(song.description).to eq("a description")
        expect(song.duration_in_seconds).to eq(1500)
        expect(song.license).to eq("youtube")
        expect(song.licensed).to eq(false)
        expect(song.thumbnail_url).to eq("https://i.ytimg.com/vi/bnVUHWCynig/default.jpg")
        expect(song.youtube_tags).to match_array(%w[dope chill beatz])
        expect(data[:errors]).to be_blank

        expect(song.users).to include(current_user)
      end
    end

    context "when song already exists" do
      it "does not modify song but does associate to user" do
        song = create(:song, youtube_id: "the-youtube-id")
        expect(Yt::Video).not_to receive(:new)

        expect do
          graphql_request(
            query: query,
            variables: { youtubeId: "the-youtube-id" },
            user: current_user
          )
        end.not_to change(Song, :count)

        data = json_body.dig(:data, :songCreate)
        id = data.dig(:song, :id)

        expect(song.id).to eq(id)
        expect(data[:errors]).to be_blank
        expect(song.users).to include(current_user)
      end

      it "does not modify song or association with user when already in library" do
        song = create(:song, youtube_id: "the-youtube-id")
        LibraryRecord.create!(song: song, user: current_user)
        expect(Yt::Video).not_to receive(:new)

        expect do
          graphql_request(
            query: query,
            variables: { youtubeId: "the-youtube-id" },
            user: current_user
          )
        end.to not_change(Song, :count).and(not_change(LibraryRecord, :count))

        data = json_body.dig(:data, :songCreate)
        id = data.dig(:song, :id)

        expect(song.id).to eq(id)
        expect(data[:errors]).to be_blank
      end
    end

    context "when adding a song from another user" do
      let!(:song) { create(:song, youtube_id: "the-youtube-id") }

      it "sets the source of the song to that other user" do
        other_user = create(:user)
        graphql_request(
          query: query,
          variables: { youtubeId: "the-youtube-id", fromUserId: other_user.id },
          user: current_user
        )

        expect(current_user.songs).to include(song)
        record = current_user.library_records.find_by(song_id: song.id)
        expect(record.source).to eq("saved_from_history")
        expect(record.from_user_id).to eq(other_user.id)
      end

      it "does not reset the source of the song" do
        # current_user has already added the song to their library
        LibraryRecord.create!(user: current_user, song: song)

        other_user = create(:user)
        graphql_request(
          query: query,
          variables: { youtubeId: "the-youtube-id", fromUserId: other_user.id },
          user: current_user
        )

        expect(current_user.songs).to include(song)
        record = current_user.library_records.find_by(song_id: song.id)
        expect(record.source).to be_blank
        expect(record.from_user_id).to be_blank
      end
    end
  end

  context "when missing required attributes" do
    it "fails to persist when youtube_id is not specified" do
      expect(Yt::Video).not_to receive(:new)
      expect do
        graphql_request(
          query: query,
          variables: { youtubeId: "" },
          user: current_user
        )
      end.not_to change(Song, :count)

      data = json_body.dig(:data, :songCreate)

      expect(data[:song]).to be_nil
      expect(data[:errors]).to match_array([include("Youtube can't be blank")])
    end
  end
end
