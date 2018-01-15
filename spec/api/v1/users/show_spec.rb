require 'rails_helper'

RSpec.describe 'users#show', type: :request do
  let(:params) { {} }

  subject(:make_request) do
    jsonapi_get "/api/v1/users/#{user.id}",
                params: params
  end

  describe 'basic fetch' do
    let!(:user) { create(:user) }

    xit 'serializes the resource correctly' do
      make_request
      assert_payload(:user, user, json_item)
    end
  end
end
