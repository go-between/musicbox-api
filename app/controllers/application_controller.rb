class ApplicationController < ActionController::API
  # Bootstrap jsonapi_suite with relevant modules
  include JsonapiSuite::ControllerMixin

  register_exception JsonapiCompliable::Errors::RecordNotFound,
                     status: 404

  # rescue_from Exception do |e|
  #   # handle_exception(e)
  # end

  before_action :authenticate_request!

  private

  def authenticate_request!
    if valid_token?
      @current_user = User.find(auth_token[:user_id])
    else
      render json: {}, status: :unauthorized
    end
  rescue JWT::VerificationError, JWT::DecodeError
    render json: {}, status: :unauthorized
  end

  def valid_token?
    request.headers['Authorization'].present? && auth_token.present?
  end

  def auth_token
    @auth_token ||= JsonWebToken.decode(request.headers['Authorization'].split(' ').last)
  end
end
