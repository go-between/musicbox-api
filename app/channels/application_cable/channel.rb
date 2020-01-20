# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base

    def subscribe_for_current_user
      return reject if current_user.active_room.blank?

      stream_for current_user.active_room
    end
  end
end
