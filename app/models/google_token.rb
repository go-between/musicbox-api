require 'google/apis/plus_v1'
require 'signet/oauth_2/client'

class GoogleToken
  attr_accessor :google_user, :user

  def initialize(google_user:, user:)
    @google_user = google_user
    @user = user
  end

  def id
    google_user.id
  end

  def user_id
    user.id
  end

  def access_token
    JsonWebToken.encode(user_id: user.id)
  end
end
