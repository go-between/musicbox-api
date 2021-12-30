# frozen_string_literal: true

require './config/boot'
require './config/environment'

module Clockwork
  every(2.seconds, 'room-poll') do
    RoomQueuePoller.new.poll!
  end
end
