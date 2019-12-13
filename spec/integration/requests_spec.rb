# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Requests Integration', type: :request do
  include ActionCable::TestHelper
  include AuthHelper
  include GraphQLHelper
  include JsonHelper

  let!(:room) { create(:room) }
  let!(:truman) { create(:user, name: "truman") }
  let!(:dan) { create(:user, name: "dan") }
  let!(:sean) { create(:user, name: "sean") }

  it "Allows two users to share a meaningful experience together" do
    Sidekiq::Testing.inline! do
      # Everybody joins the room
      expect do
        authed_post(
          url: '/api/v1/graphql',
          body: { query: join_room_mutation(room_id: room.id) },
          user: truman
        )
      end.to broadcast_to(UsersChannel.broadcasting_for(room)).with { |data|
        has_truman = data.dig("data", "room", "users").any? { |d| d["id"] == truman.id }
        expect(has_truman).to eq(true)

        has_dan = data.dig("data", "room", "users").any? { |d| d["id"] == dan.id }
        expect(has_dan).to eq(false)

        has_sean = data.dig("data", "room", "users").any? { |d| d["id"] == sean.id }
        expect(has_sean).to eq(false)
      }

      expect do
        authed_post(
          url: '/api/v1/graphql',
          body: { query: join_room_mutation(room_id: room.id) },
          user: dan
        )
      end.to broadcast_to(UsersChannel.broadcasting_for(room)).with { |data|
        has_truman = data.dig("data", "room", "users").any? { |d| d["id"] == truman.id }
        expect(has_truman).to eq(true)

        has_dan = data.dig("data", "room", "users").any? { |d| d["id"] == dan.id }
        expect(has_dan).to eq(true)

        has_sean = data.dig("data", "room", "users").any? { |d| d["id"] == sean.id }
        expect(has_sean).to eq(false)
      }

      expect do
        authed_post(
          url: '/api/v1/graphql',
          body: { query: join_room_mutation(room_id: room.id) },
          user: sean
        )
      end.to broadcast_to(UsersChannel.broadcasting_for(room)).with { |data|
        has_truman = data.dig("data", "room", "users").any? { |d| d["id"] == truman.id }
        expect(has_truman).to eq(true)

        has_dan = data.dig("data", "room", "users").any? { |d| d["id"] == dan.id }
        expect(has_dan).to eq(true)

        has_sean = data.dig("data", "room", "users").any? { |d| d["id"] == sean.id }
        expect(has_sean).to eq(true)
      }

      # Users add songs to their library
      # which don't broadcast so we'll use factories

      star_fighter = create(:song, name: "Star Fighter", duration_in_seconds: 100)
      hootsforce = create(:song, name: "Hootsforce", duration_in_seconds: 100)
      dont_move = create(:song, name: "Don't Move", duration_in_seconds: 100)
      unicorn = create(:song, name: "Unicorn", duration_in_seconds: 100)
      midnight_city = create(:song, name: "Midnight City", duration_in_seconds: 100)

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

        authed_post(
          url: '/api/v1/graphql',
          body: { query: order_room_playlist_records_mutation(room.id, records) },
          user: dan
        )
      end.to broadcast_to(QueuesChannel.broadcasting_for(room)).with { |data|
        songs = data.dig("data", "roomPlaylist")
        dan_unicorn_id = songs.first["id"]

        expect(songs.first.dig("song", "id")).to eq(unicorn.id)
        expect(songs.first.dig("user", "email")).to eq(dan.email)
      }

      # Dan enqueues another song
      expect do
        records = [
          { song_id: unicorn.id, room_playlist_record_id: dan_unicorn_id },
          { song_id: midnight_city.id }
        ]

        authed_post(
          url: '/api/v1/graphql',
          body: { query: order_room_playlist_records_mutation(room.id, records) },
          user: dan
        )
      end.to broadcast_to(QueuesChannel.broadcasting_for(room)).with { |data|
        songs = data.dig("data", "roomPlaylist")
        expect(songs.first.dig("song", "id")).to eq(unicorn.id)
        expect(songs.first.dig("user", "email")).to eq(dan.email)

        dan_midnight_city_id = songs.second["id"]
        expect(songs.second.dig("song", "id")).to eq(midnight_city.id)
        expect(songs.second.dig("user", "email")).to eq(dan.email)
      }

      # Truman enqueues a song
      expect do
        records = [
          { song_id: star_fighter.id }
        ]

        authed_post(
          url: '/api/v1/graphql',
          body: { query: order_room_playlist_records_mutation(room.id, records) },
          user: truman
        )
      end.to broadcast_to(QueuesChannel.broadcasting_for(room)).with { |data|
        songs = data.dig("data", "roomPlaylist")
        expect(songs.first["id"]).to eq(dan_unicorn_id)

        # Truman is second in rotation, so his first song comes after
        # Dan's first
        truman_starfighter_id = songs.second["id"]
        expect(songs.second.dig("song", "id")).to eq(star_fighter.id)
        expect(songs.second.dig("user", "email")).to eq(truman.email)

        expect(songs.third["id"]).to eq(dan_midnight_city_id)
      }

      # Truman enqueues another song
      expect do
        records = [
          { song_id: star_fighter.id, room_playlist_record_id: truman_starfighter_id },
          { song_id: hootsforce.id }
        ]

        authed_post(
          url: '/api/v1/graphql',
          body: { query: order_room_playlist_records_mutation(room.id, records) },
          user: truman
        )
      end.to broadcast_to(QueuesChannel.broadcasting_for(room)).with { |data|
        songs = data.dig("data", "roomPlaylist")
        expect(songs.first["id"]).to eq(dan_unicorn_id)
        expect(songs.second["id"]).to eq(truman_starfighter_id)
        expect(songs.third["id"]).to eq(dan_midnight_city_id)

        truman_hootsforce_id = songs.fourth["id"]
        expect(songs.fourth.dig("song", "id")).to eq(hootsforce.id)
        expect(songs.fourth.dig("user", "email")).to eq(truman.email)
      }

    end
  end
end
