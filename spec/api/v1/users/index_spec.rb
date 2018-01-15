require 'rails_helper'

RSpec.describe 'users#index', type: :request do
  let(:params) { {} }

  subject(:make_request) do
    jsonapi_get '/api/v1/users',
                params: params
  end

  describe 'basic fetch' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    xit 'serializes the list correctly' do
      make_request
      expect(json_ids(true)).to match_array([user1.id, user2.id])
      assert_payload(:user, user1, json_items[0])
      assert_payload(:user, user2, json_items[1])
    end
  end
end
