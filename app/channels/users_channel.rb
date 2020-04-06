# frozen_string_literal: true

class UsersChannel < ApplicationCable::Channel
  def unsubscribed
    return if current_user.blank?

    remove_from_room!
  end

  private

  def remove_from_room!
    return if current_user.active_room_id.blank?

    current_user.update!(active_room: nil)
    BroadcastTeamWorker.perform_async(current_user.active_team_id)
  end
end
