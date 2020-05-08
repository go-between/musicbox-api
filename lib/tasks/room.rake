# frozen_string_literal: true

namespace :room do
  desc "Starts loop to poll all rooms for new songs to play"
  task poll_queue: :environment do
    poller = RoomQueuePoller.new

    loop do
      poller.poll!
      sleep(0.1)
    end
  end
end
