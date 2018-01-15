require 'rails_helper'

RSpec.describe 'users#create', type: :request do
  subject(:make_request) do
    jsonapi_post '/api/v1/users', payload
  end

  describe 'basic create' do
    let(:payload) do
      {
        data: {
          type: 'users',
          attributes: {
            # ... your attrs here
          }
        }
      }
    end

    xit 'creates the resource' do
      expect do
        make_request
      end.to change { User.count }.by(1)
      user = User.last

      assert_payload(:user, user, json_item)
    end
  end
end
