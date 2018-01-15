require 'rails_helper'

RSpec.describe 'google_tokens#create', type: :request do
  subject(:make_request) do
    jsonapi_post '/api/v1/google_tokens', payload
  end

  describe 'basic create' do
    let(:payload) do
      {
        data: {
          type: 'google_tokens',
          attributes: {
            # ... your attrs here
          }
        }
      }
    end

    xit 'creates the resource' do
      expect do
        make_request
      end.to change { GoogleToken.count }.by(1)
      google_token = GoogleToken.last

      assert_payload(:google_token, google_token, json_item)
    end
  end
end
