# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requests Integration', type: :request do
  include ActionCable::TestHelper
  include AuthHelper
  include GraphQLHelper
  include JsonHelper

  let!(:team) { create(:team) }
  let!(:room) { create(:room, team: team) }
  let!(:truman) { create(:user, name: 'truman', teams: [team]) }
  let!(:dan) { create(:user, name: 'dan', teams: [team]) }
  let!(:sean) { create(:user, name: 'sean', teams: [team]) }

  it 'Allows three users to share a meaningful experience together' do
    Sidekiq::Testing.inline! do
      # Everybody joins the room
      expect do
        graphql_request(
          query: room_activate_mutation(room_id: room.id),
          user: truman
        )
      end.to(broadcast_to(UsersChannel.broadcasting_for(room)).with do |data|
        has_truman = data.dig('data', 'room', 'users').any? { |d| d['id'] == truman.id }
        expect(has_truman).to eq(true)

        has_dan = data.dig('data', 'room', 'users').any? { |d| d['id'] == dan.id }
        expect(has_dan).to eq(false)

        has_sean = data.dig('data', 'room', 'users').any? { |d| d['id'] == sean.id }
        expect(has_sean).to eq(false)
      end)

      expect do
        graphql_request(
          query: room_activate_mutation(room_id: room.id),
          user: dan
        )
      end.to(broadcast_to(UsersChannel.broadcasting_for(room)).with do |data|
        has_truman = data.dig('data', 'room', 'users').any? { |d| d['id'] == truman.id }
        expect(has_truman).to eq(true)

        has_dan = data.dig('data', 'room', 'users').any? { |d| d['id'] == dan.id }
        expect(has_dan).to eq(true)

        has_sean = data.dig('data', 'room', 'users').any? { |d| d['id'] == sean.id }
        expect(has_sean).to eq(false)
      end)

      expect do
        graphql_request(
          query: room_activate_mutation(room_id: room.id),
          user: sean
        )
      end.to(broadcast_to(UsersChannel.broadcasting_for(room)).with do |data|
        has_truman = data.dig('data', 'room', 'users').any? { |d| d['id'] == truman.id }
        expect(has_truman).to eq(true)

        has_dan = data.dig('data', 'room', 'users').any? { |d| d['id'] == dan.id }
        expect(has_dan).to eq(true)

        has_sean = data.dig('data', 'room', 'users').any? { |d| d['id'] == sean.id }
        expect(has_sean).to eq(true)
      end)

      # No one has joined the song rotation yet
      expect(room.reload.user_rotation).to be_empty

      # Users add songs to their library
      # this doesn't broadcast so we'll use factories

      star_fighter = create(:song, name: 'Star Fighter', duration_in_seconds: 100)
      hootsforce = create(:song, name: 'Hootsforce', duration_in_seconds: 100)
      dont_move = create(:song, name: "Don't Move", duration_in_seconds: 100)
      unicorn = create(:song, name: 'Unicorn', duration_in_seconds: 100)
      midnight_city = create(:song, name: 'Midnight City', duration_in_seconds: 100)

      truman.songs << star_fighter
      truman.songs << hootsforce
      dan.songs << unicorn
      dan.songs << midnight_city
      sean.songs << dont_move
      sean.songs << unicorn

      # We're gonna capture these as they get enqueued
      truman_starfighter_id = nil
      truman_hootsforce_id = nil
      dan_unicorn_id = nil
      dan_midnight_city_id = nil
      sean_dont_move_id = nil
      sean_unicorn_id = nil

      # Dan enqueues a song
      expect do
        records = [
          { song_id: unicorn.id }
        ]

        graphql_request(
          query: order_room_playlist_records_mutation(records: records),
          user: dan
        )
      end.to(broadcast_to(QueuesChannel.broadcasting_for(room)).with do |data|
        songs = data.dig('data', 'roomPlaylist')
        expect(songs.size).to eq(1)

        dan_unicorn_id = songs.first['id']

        expect(songs.first.dig('song', 'id')).to eq(unicorn.id)
        expect(songs.first.dig('user', 'email')).to eq(dan.email)
      end)

      # Dan is now in song rotation
      expect(room.reload.user_rotation).to eq([dan.id])

      # Dan enqueues another song
      expect do
        records = [
          { song_id: unicorn.id, room_playlist_record_id: dan_unicorn_id },
          { song_id: midnight_city.id }
        ]

        graphql_request(
          query: order_room_playlist_records_mutation(records: records),
          user: dan
        )
      end.to(broadcast_to(QueuesChannel.broadcasting_for(room)).with do |data|
        songs = data.dig('data', 'roomPlaylist')
        expect(songs.size).to eq(2)

        expect(songs.first.dig('song', 'id')).to eq(unicorn.id)
        expect(songs.first.dig('user', 'email')).to eq(dan.email)

        dan_midnight_city_id = songs.second['id']
        expect(songs.second.dig('song', 'id')).to eq(midnight_city.id)
        expect(songs.second.dig('user', 'email')).to eq(dan.email)
      end)

      # Truman enqueues a song
      expect do
        records = [
          { song_id: star_fighter.id }
        ]

        graphql_request(
          query: order_room_playlist_records_mutation(records: records),
          user: truman
        )
      end.to(broadcast_to(QueuesChannel.broadcasting_for(room)).with do |data|
        songs = data.dig('data', 'roomPlaylist')
        expect(songs.size).to eq(3)
        expect(songs.first['id']).to eq(dan_unicorn_id)

        # Truman is second in rotation, so his first song comes after
        # Dan's first
        truman_starfighter_id = songs.second['id']
        expect(songs.second.dig('song', 'id')).to eq(star_fighter.id)
        expect(songs.second.dig('user', 'email')).to eq(truman.email)

        expect(songs.third['id']).to eq(dan_midnight_city_id)
      end)

      # Truman now follows Dan in rotation
      expect(room.reload.user_rotation).to eq([dan.id, truman.id])

      # Sean enqueues a song
      expect do
        records = [
          { song_id: dont_move.id }
        ]

        graphql_request(
          query: order_room_playlist_records_mutation(records: records),
          user: sean
        )
      end.to(broadcast_to(QueuesChannel.broadcasting_for(room)).with do |data|
        songs = data.dig('data', 'roomPlaylist')
        expect(songs.size).to eq(4)

        expect(songs.first['id']).to eq(dan_unicorn_id)
        expect(songs.second['id']).to eq(truman_starfighter_id)

        # Sean is third in rotation, so his first song comes after
        # Truman's and Dan's first
        sean_dont_move_id = songs.third['id']
        expect(songs.third.dig('song', 'id')).to eq(dont_move.id)
        expect(songs.third.dig('user', 'email')).to eq(sean.email)

        expect(songs.fourth['id']).to eq(dan_midnight_city_id)
      end)

      # Sean now follows Dan, Truman in rotation
      expect(room.reload.user_rotation).to eq([dan.id, truman.id, sean.id])

      # Sean enqueues another song
      expect do
        records = [
          { song_id: dont_move.id, room_playlist_record_id: sean_dont_move_id },
          { song_id: unicorn.id }
        ]

        graphql_request(
          query: order_room_playlist_records_mutation(records: records),
          user: sean
        )
      end.to(broadcast_to(QueuesChannel.broadcasting_for(room)).with do |data|
        songs = data.dig('data', 'roomPlaylist')
        expect(songs.size).to eq(5)

        expect(songs.first['id']).to eq(dan_unicorn_id)
        expect(songs.second['id']).to eq(truman_starfighter_id)
        expect(songs.third['id']).to eq(sean_dont_move_id)

        # A full rotation is now complete, but Dan still has a song up next
        expect(songs.fourth['id']).to eq(dan_midnight_city_id)

        # Followed by Sean
        sean_unicorn_id = songs.fifth['id']
        expect(songs.fifth.dig('song', 'id')).to eq(unicorn.id)
        expect(songs.fifth.dig('user', 'email')).to eq(sean.email)
      end)

      # Truman enqueues his last song but swaps the order
      # of the new song (hootsforce) and the previous (star fighter)
      expect do
        records = [
          { song_id: hootsforce.id },
          { song_id: star_fighter.id, room_playlist_record_id: truman_starfighter_id }
        ]

        graphql_request(
          query: order_room_playlist_records_mutation(records: records),
          user: truman
        )
      end.to(broadcast_to(QueuesChannel.broadcasting_for(room)).with do |data|
        songs = data.dig('data', 'roomPlaylist')
        expect(songs.size).to eq(6)

        expect(songs.first['id']).to eq(dan_unicorn_id)

        # Truman's new song is now second
        truman_hootsforce_id = songs.second['id']
        expect(songs.second.dig('song', 'id')).to eq(hootsforce.id)
        expect(songs.second.dig('user', 'email')).to eq(truman.email)

        # Followed by the other songs in order
        expect(songs.third['id']).to eq(sean_dont_move_id)
        expect(songs.fourth['id']).to eq(dan_midnight_city_id)
        expect(songs.fifth['id']).to eq(truman_starfighter_id)
        expect(songs[5]['id']).to eq(sean_unicorn_id)
      end)

      # A request for the room's playlist returns the correct order
      graphql_request(
        query: room_playlist_query(room_id: room.id),
        user: truman
      )

      songs = json_body.dig(:data, :roomPlaylist)
      expect(songs.count).to eq(6)

      playlist_song_ids = songs.map { |s| s[:id] }
      expected_song_ids = [
        dan_unicorn_id,
        truman_hootsforce_id,
        sean_dont_move_id,
        dan_midnight_city_id,
        truman_starfighter_id,
        sean_unicorn_id
      ]
      expect(playlist_song_ids).to eq(expected_song_ids)
    end
  end
end
