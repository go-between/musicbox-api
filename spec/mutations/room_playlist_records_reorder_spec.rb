# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Room Playlist Records Reorder", type: :request do
  include AuthHelper
  include GraphQLHelper
  include JsonHelper

  let(:room) { create(:room) }
  let(:current_user) { create(:user, active_room_id: room.id) }

  describe "waiting song state" do
    it "indicates that the room has songs waiting to be played" do
      room.update!(waiting_songs: false)
      record1 = create(:room_playlist_record, room: room, order: 0, user: current_user)

      records = [
        { song_id: record1.song_id, room_playlist_record_id: record1.id }
      ]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      expect(room.reload.waiting_songs).to eq(true)
    end
  end

  describe "song ordering" do
    it "reorders existing records" do
      record1 = create(:room_playlist_record, room: room, order: 0, user: current_user)
      record2 = create(:room_playlist_record, room: room, order: 1, user: current_user)

      records = [
        { song_id: record2.song_id, room_playlist_record_id: record2.id },
        { song_id: record1.song_id, room_playlist_record_id: record1.id }
      ]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      expect(record1.reload.order).to eq(1)
      expect(record2.reload.order).to eq(0)
    end

    it "removes records that are not present in a new ordering for this user and room" do
      record1 = create(:room_playlist_record, room: room, order: 0, user: current_user)
      record2 = create(:room_playlist_record, room: room, order: 1, user: current_user)
      record3 = create(:room_playlist_record, room: room, order: 2, user: current_user)
      other_room_record = create(:room_playlist_record, room: create(:room), order: 2, user: current_user)
      other_user_record = create(:room_playlist_record, room: room, order: 2, user: create(:user))
      played_record = create(:room_playlist_record, room: room, order: 2, user: current_user, play_state: :played)

      record2_id = record2.id

      records = [
        { song_id: record3.song_id, room_playlist_record_id: record3.id },
        { song_id: record1.song_id, room_playlist_record_id: record1.id }
      ]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      expect(RoomPlaylistRecord.exists?(id: record2_id)).to eq(false)
      expect(record3.reload.order).to eq(0)
      expect(record1.reload.order).to eq(1)
      expect(other_room_record.reload).to be_persisted
      expect(other_user_record.reload).to be_persisted
      expect(played_record.reload).to be_persisted
    end

    it "places new records in order" do
      record = create(:room_playlist_record, room: room, order: 0, user: current_user)
      song1 = create(:song)
      song2 = create(:song)

      records = [
        { song_id: song1.id },
        { song_id: record.song_id, room_playlist_record_id: record.id },
        { song_id: song2.id }
      ]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      new_record1 = RoomPlaylistRecord.find_by(user: current_user, song_id: song1.id, room: room)
      new_record2 = RoomPlaylistRecord.find_by(user: current_user, song_id: song2.id, room: room)
      expect(new_record1.order).to eq(0)
      expect(record.reload.order).to eq(1)
      expect(new_record2.order).to eq(2)
    end
  end

  describe "user rotation" do
    let(:song) { create(:song) }

    it "places the user in the song rotation when the rotation is empty" do
      room.update!(user_rotation: [])

      records = [{ song_id: song.id }]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(0)

      expect(room.reload.user_rotation).to eq([current_user.id])
    end

    it "places the user at the end of an existing song rotation" do
      existing_user_id = SecureRandom.uuid
      room.update!(user_rotation: [existing_user_id])

      records = [{ song_id: song.id }]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(0)

      expect(room.reload.user_rotation).to eq([existing_user_id, current_user.id])
    end

    it "does not re-add the user if they are already in the song rotation" do
      existing_user_id = SecureRandom.uuid
      room.update!(user_rotation: [current_user.id, existing_user_id])

      records = [{ song_id: song.id }]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(0)

      expect(room.reload.user_rotation).to eq([current_user.id, existing_user_id])
    end
  end

  describe "errors" do
    it "ignores records that can not be ordered" do
      own_record = create(:room_playlist_record, room: room, order: 0, user: current_user)
      song = create(:song)
      user = create(:user)
      other_record = create(:room_playlist_record, room: room, order: 0, user: user)
      nonexistant_song_id = SecureRandom.uuid
      records = [
        { song_id: nonexistant_song_id },
        { song_id: own_record.song_id, room_playlist_record_id: own_record.id },
        { song_id: other_record.song_id, room_playlist_record_id: other_record.id },
        { song_id: song.id }
      ]
      graphql_request(
        query: room_playlist_records_reorder_mutation(records: records),
        user: current_user
      )

      # Note:  We ignore records that we cannot process but don't care too
      #        much to keep things strictly ordered from 0-N.  Relative ordering
      #        is fine, so `own_record` is in slot "1", and `new_record` is in
      #        slot "3" (instead of "0", "1", respectively).
      expect(own_record.reload.order).to eq(1)
      new_record = RoomPlaylistRecord.find_by(user: current_user, song_id: song.id, room: room)
      expect(new_record.order).to eq(3)
    end
  end
end
