class SongsController < ApplicationController
  # Mark this as a JSONAPI controller, associating with the given resource
  jsonapi resource: SongResource

  # Reference a strong resource payload defined in
  # config/initializers/strong_resources.rb
  strong_resource :song
  # Run strong parameter validation for these actions.
  # Invalid keys will be dropped.
  # Invalid value types will log or raise based on the configuration
  # ActionController::Parameters.action_on_invalid_parameters
  before_action :apply_strong_params, only: %i[create]

  def create
    song, success = jsonapi_create.to_a
    byebug

    if success
      render_jsonapi(song, scope: false)
    else
      render_errors_for(song)
    end
  end
end
