require 'jsonapi_swagger_helpers'

class DocsController < ActionController::API
  include JsonapiSwaggerHelpers::DocsControllerMixin

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'MusicBox'
      key :description, '--'
      contact do
        key :name, '--'
        key :email, '--'
      end
    end
    key :basePath, '/api'
    key :consumes, ['application/json']
    key :produces, ['application/json']
  end
  jsonapi_resource '/v1/users'
  jsonapi_resource '/v1/google_tokens'
end
