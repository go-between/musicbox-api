# frozen_string_literal: true

class ApplicationController < ActionController::API
  private

  def current_user
    return @current_user if defined? @current_user
    return unless doorkeeper_token.present?

    @current_user = User.find(doorkeeper_token.resource_owner_id)
  end
end
