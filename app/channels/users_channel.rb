# frozen_string_literal: true

class UsersChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_user.active_room.blank?

    stream_for current_user.active_room
  end
end
