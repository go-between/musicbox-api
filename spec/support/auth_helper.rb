# frozen_string_literal: true

module AuthHelper
  def auth_headers
    {
      Authorization: "Bearer #{token.token}"
    }
  end

  def token
    return @_token if defined? @_token

    @_token = Doorkeeper::AccessToken.create!(resource_owner_id: current_user.id)
  end

  def current_user
    return @_current_user if defined? @_current_user

    @_current_user = create(:user)
  end

  def authed_post(url, body, headers = {})
    post(url, params: body, headers: headers.merge(auth_headers))
  end
end
