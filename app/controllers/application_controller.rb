class ApplicationController < ActionController::API
  # rescue_from Exception do |e|
  #   # handle_exception(e)
  # end

  before_action :doorkeeper_authorize!

  private

  def current_user
    return @_current_user if defined? @_current_user

    @_current_user = User.find(doorkeeper_token.resource_owner_id)
  end
end
