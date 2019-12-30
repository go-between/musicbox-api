# user = User.find_or_create_by()
def graphiql_doorkeeper_token
  user = User.find_or_initialize_by(email: "graphiql-test@trumanshuck.com")
  user.update!(password: "hunter222") unless user.persisted?

  token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id, expires_in: nil)
  token.token
end

GraphiQL::Rails.config.headers['Authorization'] = -> (context) { "Bearer #{graphiql_doorkeeper_token}" }
