# frozen_string_literal: true

class TeamChannel < ApplicationCable::Channel
  def subscribed
    return reject if current_user.active_team.blank?

    stream_for current_user.active_team
  end
end
