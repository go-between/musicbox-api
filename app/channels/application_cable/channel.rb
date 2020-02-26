# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def subscribed
      return reject if current_user.active_room.blank?

      stream_for current_user.active_room
    end
  end
end
