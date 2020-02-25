# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = current_user
    end

    protected

    def current_user
      return @current_user if defined? @current_user

      user = User.find_by(id: access_token.try(:resource_owner_id))
      return reject_unauthorized_connection if user.blank?

      @current_user = user
    end

    def access_token
      @access_token ||= Doorkeeper::AccessToken.by_token(
        request.query_parameters[:token]
      )
    end
  end
end
