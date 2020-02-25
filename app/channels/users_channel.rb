# frozen_string_literal: true

class UsersChannel < ApplicationCable::Channel
  delegate :subscribed, to: :subscribe_for_current_user

  def unsubscribed
    return if cached_current_user.blank?

    remove_from_room!
  end

  private

  def remove_from_room!
    return if cached_current_user.active_room_id.blank?

    previous_room = cached_current_user.active_room_id
    cached_current_user.update!(active_room: nil)
    BroadcastUsersWorker.perform_async(previous_room)
  end
end
