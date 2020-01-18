# frozen_string_literal: true

def graphiql_doorkeeper_token
  user = User.find_by(email: "a@a.a")
  return if user.blank?

  token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id, expires_in: nil)
  token.token
end

GraphiQL::Rails.config.headers["Authorization"] = ->(_context) { "Bearer #{graphiql_doorkeeper_token}" }
