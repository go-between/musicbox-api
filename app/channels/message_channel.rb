# frozen_string_literal: true

class MessageChannel < ApplicationCable::Channel
  delegate :subscribed, to: :subscribe_for_current_user
end
