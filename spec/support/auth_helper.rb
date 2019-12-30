# frozen_string_literal: true

module AuthHelper
  def auth_headers(user)
    {
      Authorization: "Bearer #{token(user).token}"
    }
  end

  def token(user)
    @_token = {} unless defined? @_token
    return @_token[user] if @_token.key?(user)

    @_token[user] = Doorkeeper::AccessToken.create!(resource_owner_id: user.id)
  end

  def authed_post(url:, body:, headers: {}, user: create(:user))
    post(url, params: body, headers: headers.merge(auth_headers(user)))
  end
end
