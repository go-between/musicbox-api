# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def current_user
    return @_current_user if defined? @_current_user
    return unless doorkeeper_token.present?

    @_current_user = User.find(doorkeeper_token.resource_owner_id)
  end
end
