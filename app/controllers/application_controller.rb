class ApplicationController < ActionController::API
  # Bootstrap jsonapi_suite with relevant modules
  include JsonapiSuite::ControllerMixin

  register_exception JsonapiCompliable::Errors::RecordNotFound,
                     status: 404

  # rescue_from Exception do |e|
  #   # handle_exception(e)
  # end

  def attrs
    deserialized_params.attributes
  end
end
