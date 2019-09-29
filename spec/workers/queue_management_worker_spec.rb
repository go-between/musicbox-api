require 'rails_helper'
RSpec.describe QueueManagementWorker, type: :worker do
  include ActiveSupport::Testing::TimeHelpers

  let(:started) { Time.zone.now }
  let(:song) { create(:song) }
  let(:room) { create(:room) }
  let(:user) { create(:user) }
  let(:worker) { QueueManagementWorker.new }

  context "when queue is empty" do
    it "removes the current record" do
      room.update!(current_record: create(:room_playlist_record, room: room))
      worker.perform(room.id)

      room.reload
      expect(room.current_record).to eq(nil)
    end

    it "re-queues a new worker" do
      expect(QueueManagementWorker).to receive(:perform_in).with(1.second, room.id)
      worker.perform(room.id)
    end

    context "when its previous run processed the last song" do
      before(:each) do
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

    context "when its previous run was empty" do
      it "does not broadcast to now playing" do
        worker.perform(room.id)
        expect(BroadcastNowPlayingWorker).to_not have_enqueued_sidekiq_job(anything)
      end

      it "does not broadcasts to queue" do
        worker.perform(room.id)
        expect(BroadcastPlaylistWorker).to_not have_enqueued_sidekiq_job(anything)
      end
    end
  end

  context "when queue has songs to play" do
    before(:each) do
      room.update!(user_rotation: [user.id])
      @record = create(:room_playlist_record,
        room: room,
        song: song,
        user: user,
        play_state: "waiting"
      )
    end

    it "updates the room's current record" do
      worker.perform(room.id)

      room.reload
      expect(room.current_record).to eq(@record)
    end

    it "sets the current record to played" do
      travel_to(Time.utc(3000, 1, 1, 0, 0, 0)) do
        worker.perform(room.id)
      end

      room.reload
      expect(room.current_record.played_at).to eq("3000-01-01 00:00:00.000000000 +0000")
      expect(room.current_record).to be_played
    end

    it "re-enqueues a new worker" do
      song.update!(duration_in_seconds: 432)

      expect(QueueManagementWorker).to receive(:perform_in).with(432.second, room.id)
      worker.perform(room.id)
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
