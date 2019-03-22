class RoomQueuesController < ApplicationController
  # Mark this as a JSONAPI controller, associating with the given resource
  jsonapi resource: RoomQueueResource

  # Reference a strong resource payload defined in
  # config/initializers/strong_resources.rb
  strong_resource :room_queue
  # Run strong parameter validation for these actions.
  # Invalid keys will be dropped.
  # Invalid value types will log or raise based on the configuration
  # ActionController::Parameters.action_on_invalid_parameters
  before_action :apply_strong_params, only: %i[create]

  def create
    room_queue, success = jsonapi_create.to_a

    if success
      render_jsonapi(room_queue, scope: false)
    else
      render_errors_for(room_queue)
    end
  end
end
