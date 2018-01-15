class GooglePlusUser
  def self.from_code(code:)
    google_plus = Google::Apis::PlusV1::PlusService.new.tap do |userinfo|
      userinfo.key = ENV['GOOGLE_KEY']
      userinfo.authorization = auth_client(code: code)
    end

    google_plus.get_person("me")
  end

  def self.auth_client(code:)
    Signet::OAuth2::Client.new(
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
      client_id: ENV['GOOGLE_KEY'], client_secret: ENV['GOOGLE_SECRET'],
      scope: 'email profile', redirect_uri: ENV['REDIRECT_URI']
    ).tap do |client|
      client.code = code
      client.fetch_access_token!
    end
  end
end
