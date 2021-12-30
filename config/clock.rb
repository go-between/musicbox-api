# frozen_string_literal: true

require './config/boot'
require './config/environment'

module Clockwork
  every(1.second, 'room-poll') do
    RoomQueuePoller.new.poll!
  end
end
