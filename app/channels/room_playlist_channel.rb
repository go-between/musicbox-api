# frozen_string_literal: true

class RoomPlaylistChannel < ApplicationCable::Channel
  delegate :subscribed, to: :subscribe_for_current_user
end
