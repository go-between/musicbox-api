class RoomsController < ApplicationController
  # Mark this as a JSONAPI controller, associating with the given resource
  jsonapi resource: RoomResource

  # Reference a strong resource payload defined in
  # config/initializers/strong_resources.rb
  strong_resource :room
  # Run strong parameter validation for these actions.
  # Invalid keys will be dropped.
  # Invalid value types will log or raise based on the configuration
  # ActionController::Parameters.action_on_invalid_parameters
  # before_action :apply_strong_params, only: %i[create update]

  def show
    ActionCable.server.broadcast 'messages', foo: :bar

    scope = jsonapi_scope(Room.where(id: params[:id]))
    instance = scope.resolve.first
    raise JsonapiCompliable::Errors::RecordNotFound unless instance
    render_jsonapi(instance, scope: false)
  end
end
