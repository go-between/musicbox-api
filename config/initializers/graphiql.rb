# frozen_string_literal: true

# Note:  This is almost certainly an awful practice
#        because it opens up a hole where anyone can sign in
#        as this user.  We should do something about this uh eventually.
def graphiql_doorkeeper_token
  user = User.find_or_initialize_by(email: 'graphiql-test@trumanshuck.com')
  user.update!(password: 'hunter222') unless user.persisted?

  token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id, expires_in: nil)
  token.token
end

GraphiQL::Rails.config.headers['Authorization'] = ->(_context) { "Bearer #{graphiql_doorkeeper_token}" }
