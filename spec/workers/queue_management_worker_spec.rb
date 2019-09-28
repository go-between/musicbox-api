require 'rails_helper'
RSpec.describe QueueManagementWorker, type: :worker do
  let(:started) { Time.zone.now }
  let(:song) { create(:song) }
  let(:room) { create(:room, current_song: song, current_song_start: started) }
  let(:user) { create(:user) }
  let(:worker) { QueueManagementWorker.new }

  context "when queue is empty" do
    it "removes the current song" do
      worker.perform(room.id)

      room.reload
      expect(room.current_song).to eq(nil)
      expect(room.current_song_start).to eq(nil)
    end

    it "re-queues a new worker" do
      expect(QueueManagementWorker).to receive(:perform_in).with(1.second, room.id)
      worker.perform(room.id)
    end

    context "when its previous run processed the last song" do
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
      before(:each) do
        room.update!(current_song: nil, current_song_start: nil)
      end

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
    let(:new_song) { create(:song) }

    before(:each) do
      create(:room_song, room: room, song: new_song, user: user)
    end

    it "updates the room's current song" do
      Timecop.freeze(3000, 1, 1, 0, 0, 0) do
        worker.perform(room.id)
      end

      room.reload
      expect(room.current_song).to eq(new_song)
      expect(room.current_song_start).to eq("3000-01-01 00:00:00.000000000 +0000")
    end

    it "destroys the queue record" do
      worker.perform(room.id)
      expect(RoomSong.exists?(room: room, song: song, user: user)).to eq(false)
    end

    it "re-enqueues a new worker" do
      new_song.update!(duration_in_seconds: 432)

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
