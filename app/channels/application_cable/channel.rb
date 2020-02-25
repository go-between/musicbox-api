# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def subscribe_for_current_user
      return reject if cached_current_user.active_room.blank?

      stream_for cached_current_user.active_room
    end

    private

    def cached_current_user
      return @cached_current_user if defined? @cached_current_user

      prospective_current_user = current_user
      return if prospective_current_user.blank?

      @cached_current_user = prospective_current_user
    end
  end
end
