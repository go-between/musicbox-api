# frozen_string_literal: true

require "rails_helper"
RSpec.describe QueueManagementWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  let(:started) { Time.zone.now }
  let(:song) { create(:song, duration_in_seconds: 10) }
  let(:room) { create(:room, queue_processing: true) }
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  context "when queue is empty" do
    it "removes the current record" do
      room.update!(current_record: create(:room_playlist_record, room: room))
      worker.perform(room.id)

      room.reload
      expect(room.current_record).to be_nil
      expect(room.playing_until).to be_nil
      expect(room.waiting_songs).to be(false)
    end

    context "when its previous run processed the last song" do
      before do
        room.update!(current_record: create(:room_playlist_record, room: room))
      end

      it "broadcasts to queue" do
        worker.perform(room.id)
        expect(BroadcastPlaylistWorker).to have_enqueued_sidekiq_job(room.id)
      end

      it "broadcasts to now playing" do
        worker.perform(room.id)
        expect(BroadcastNowPlayingWorker).to have_enqueued_sidekiq_job(room.id)
      end
    end
  end

  context "when queue has songs to play" do
    before do
      room.update!(user_rotation: [ user.id ])
    end

    let!(:record) do
      create(
        :room_playlist_record,
        room: room,
        song: song,
        user: user,
        play_state: "waiting"
      )
    end

    it "does nothing if already playing" do
      travel_to(Time.utc(3000, 1, 1, 0, 0, 0)) do
        previous_record = create(:room_playlist_record, user: user)
        playing_until = 1.minute.from_now
        room.update!(playing_until: playing_until, current_record: previous_record)
        worker.perform(room.id)

        room.reload
        expect(room.current_record).to eq(previous_record)
        expect(room.playing_until).to eq(playing_until)
        expect(BroadcastNowPlayingWorker).not_to have_enqueued_sidekiq_job(room.id)
        expect(BroadcastPlaylistWorker).not_to have_enqueued_sidekiq_job(room.id)
      end
    end

    it "does nothing if not set to processing" do
      travel_to(Time.utc(3000, 1, 1, 0, 0, 0)) do
        previous_record = create(:room_playlist_record, user: user)
        room.update!(queue_processing: false, current_record: previous_record)
        worker.perform(room.id)

        room.reload
        expect(room.current_record).to eq(previous_record)
        expect(BroadcastNowPlayingWorker).not_to have_enqueued_sidekiq_job(room.id)
        expect(BroadcastPlaylistWorker).not_to have_enqueued_sidekiq_job(room.id)
      end
    end

    it "updates the room's current record" do
      worker.perform(room.id)

      room.reload
      expect(room.current_record).to eq(record)
    end

    it "sets the current record to played" do
      travel_to(Time.utc(3000, 1, 1, 0, 0, 0)) do
        worker.perform(room.id)
      end

      room.reload
      expect(room.current_record.played_at).to eq("3000-01-01 00:00:00.000000000 +0000")
      expect(room.current_record).to be_played
    end

    it "sets the room's playing until to the song's duration" do
      travel_to(Time.utc(3000, 1, 1, 0, 0, 0)) do
        worker.perform(room.id)
      end

      room.reload
      expect(room.playing_until).to eq("3000-01-01 00:00:10.000000000 +0000")
    end

    it "broadcasts to queue" do
      worker.perform(room.id)
      expect(BroadcastPlaylistWorker).to have_enqueued_sidekiq_job(room.id)
    end

    it "broadcasts to now playing" do
      worker.perform(room.id)
      expect(BroadcastNowPlayingWorker).to have_enqueued_sidekiq_job(room.id)
    end

    context "when user of previous record may no longer be active" do
      it "does not remove the record's user when they are still active" do
        user.update!(active_room: room)
        worker.perform(room.id)

        expect(room.reload.user_rotation).to include(user.id)
      end

      it "does not remove the record's user if they have more songs to play" do
        user.update!(active_room: nil)
        create(
          :room_playlist_record,
          room: room,
          song: song,
          user: user,
          play_state: "waiting"
        )

        worker.perform(room.id)
        expect(room.reload.user_rotation).to include(user.id)
      end

      it "does remove the user if they have no further songs to play and are not active" do
        user.update!(active_room: nil)
        record.update!(play_state: "played")
        room.update!(current_record: record)

        worker.perform(room.id)

        expect(room.reload.user_rotation).not_to include(user.id)
      end
    end
  end
end
