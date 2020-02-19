# frozen_string_literal: true

class ApplicationController < ActionController::API
  before_action :conditional_authorize!

  private

  def conditional_authorize!
    return doorkeeper_authorize! unless request.controller_class == GraphqlController

    # Note:  Okay, okay.  Maybe there's a better way to skip authentication
    #        when we accept an invitation.  But I'd prefer not to push auth
    #        down in to every query/mutation, and I'd prefer not to support
    #        a separate api resource just for accepting invitations.
    # Note:  Yeah but it's the rule of THREES so one more of these and then
    #        we'll figure out what to do instead of this.
    graphql_query = params[:query].gsub(/\s+/, "")
    return if /^mutation.*\{invitationAccept/ =~ graphql_query
    return if /^mutation.*\{teamCreate/ =~ graphql_query
    return if /^query.*\{invitation/ =~ graphql_query

    doorkeeper_authorize!
  end

  def current_user
    return @_current_user if defined? @_current_user
    return unless doorkeeper_token.present?

    @_current_user = User.find(doorkeeper_token.resource_owner_id)
  end
end
