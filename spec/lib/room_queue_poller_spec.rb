# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoomQueuePoller do
  describe "#poll!" do
    it "enqueues queue updates for pertinent rooms" do
      # Not done playing yet
      not_done = create(:room, playing_until: 1.minute.from_now)
      # No songs waiting to be played
      none_waiting = create(:room, playing_until: nil, waiting_songs: false)
      # has song, but is already processing
      already_processing = create(:room, playing_until: 1.minute.ago, queue_processing: true, waiting_songs: true)

      recently_finished1 = create(:room, playing_until: 1.second.ago)
      recently_finished2 = create(:room, playing_until: 1.minute.ago)
      with_waiting_song1 = create(:room, playing_until: nil, waiting_songs: true)
      with_waiting_song2 = create(:room, playing_until: nil, waiting_songs: true)

      poller = described_class.new
      poller.poll!

      expect(QueueManagementWorker).not_to have_enqueued_sidekiq_job(not_done.id)
      expect(QueueManagementWorker).not_to have_enqueued_sidekiq_job(none_waiting.id)
      expect(QueueManagementWorker).not_to have_enqueued_sidekiq_job(already_processing.id)
      expect(QueueManagementWorker).to have_enqueued_sidekiq_job(recently_finished1.id)
      expect(QueueManagementWorker).to have_enqueued_sidekiq_job(recently_finished2.id)
      expect(QueueManagementWorker).to have_enqueued_sidekiq_job(with_waiting_song1.id)
      expect(QueueManagementWorker).to have_enqueued_sidekiq_job(with_waiting_song2.id)
    end
  end
end
