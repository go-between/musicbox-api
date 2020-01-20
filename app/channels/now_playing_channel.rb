# frozen_string_literal: true

class NowPlayingChannel < ApplicationCable::Channel
  delegate :subscribed, to: :subscribe_for_current_user
end
