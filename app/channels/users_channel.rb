# frozen_string_literal: true

class UsersChannel < ApplicationCable::Channel
  delegate :subscribed, to: :subscribe_for_current_user

  def unsubscribed
    return if current_user.blank?

    remove_from_room!
  end

  private

  def remove_from_room!
    return if current_user.active_room_id.blank?

    previous_room = current_user.active_room_id
    current_user.update!(active_room: nil)
    BroadcastUsersWorker.perform_async(previous_room)
  end
end
