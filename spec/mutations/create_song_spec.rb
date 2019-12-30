# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create Song', type: :request do
  include AuthHelper
  include JsonHelper

  def query(youtube_id:)
    %(
      mutation {
        createSong(input:{
          youtubeId: "#{youtube_id}"
        }) {
          song {
            id
            description
            durationInSeconds
            name
            youtubeId
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe '#create' do
    context 'when song does not exist' do
      it 'creates song and associates with current user' do
        video = OpenStruct.new(duration: 1500, title: 'a title', description: 'a description')
        expect(Yt::Video).to receive(:new).with(id: 'an-id').and_return(video)

        authed_post(
          url: '/api/v1/graphql',
          body: {
            query: query(youtube_id: 'an-id')
          },
          user: current_user
        )
        data = json_body.dig(:data, :createSong)
        id = data.dig(:song, :id)

        song = Song.find(id)
        expect(song.name).to eq('a title')
        expect(song.description).to eq('a description')
        expect(song.duration_in_seconds).to eq(1500)
        expect(data[:errors]).to be_blank

        expect(song.users).to include(current_user)
      end
    end

    context 'when song already exists' do
      it 'does not modify song but does associate to user' do
        song = create(:song, youtube_id: 'the-youtube-id')
        expect(Yt::Video).not_to receive(:new)

        expect do
          authed_post(
            url: '/api/v1/graphql',
            body: {
              query: query(youtube_id: 'the-youtube-id')
            },
            user: current_user
          )
        end.not_to change(Song, :count)

        data = json_body.dig(:data, :createSong)
        id = data.dig(:song, :id)

        expect(song.id).to eq(id)
        expect(data[:errors]).to be_blank
        expect(song.users).to include(current_user)
      end

      it 'does not modify song or association with user when already in library' do
        song = create(:song, youtube_id: 'the-youtube-id')
        UserLibraryRecord.create!(song: song, user: current_user)
        expect(Yt::Video).not_to receive(:new)

        expect do
          authed_post(
            url: '/api/v1/graphql',
            body: {
              query: query(youtube_id: 'the-youtube-id')
            },
            user: current_user
          )
        end.to not_change(Song, :count).and(not_change(UserLibraryRecord, :count))

        data = json_body.dig(:data, :createSong)
        id = data.dig(:song, :id)

        expect(song.id).to eq(id)
        expect(data[:errors]).to be_blank
      end
    end
  end

  context 'when missing required attributes' do
    it 'fails to persist when youtube_id is not specified' do
      expect(Yt::Video).not_to receive(:new)
      expect do
        authed_post(
          url: '/api/v1/graphql',
          body: {
            query: query(youtube_id: nil)
          },
          user: current_user
        )
      end.not_to change(Song, :count)

      data = json_body.dig(:data, :createSong)

      expect(data[:song]).to be_nil
      expect(data[:errors]).to match_array([include("Youtube can't be blank")])
    end
  end
end
