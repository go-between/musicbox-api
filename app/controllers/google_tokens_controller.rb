class GoogleTokensController < ApplicationController
  skip_before_action :authenticate_request!

  jsonapi resource: GoogleTokenResource
  strong_resource :google_token

  before_action :apply_strong_params, only: %i[create]

  def create
    google_user = GooglePlusUser.from_code(code: deserialized_params.attributes[:code])
    email = google_user.emails.first.value

    user = User.find_or_create_by(email: email) do |user|
      user.name = google_user.display_name
      user.google_id = google_user.id
    end

    google_token = GoogleToken.new(google_user: google_user, user: user)
    render_jsonapi(google_token, scope: false)
  end
end
