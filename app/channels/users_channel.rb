# frozen_string_literal: true

class UsersChannel < ApplicationCable::Channel
  delegate :subscribed, to: :subscribe_for_current_user
end
