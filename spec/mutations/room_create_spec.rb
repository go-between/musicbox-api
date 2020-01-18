# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Room Create', type: :request do
  include AuthHelper
  include JsonHelper

  def query(name:)
    %(
      mutation {
        roomCreate(input:{
          name: "#{name}"
        }) {
          room {
            id
            name
          }
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user) }

  describe '#create' do
    it 'creates room' do
      authed_post(
        url: '/api/v1/graphql',
        body: {
          query: query(name: 'Rush Fans')
        },
        user: current_user
      )
      data = json_body.dig(:data, :roomCreate)
      id = data.dig(:room, :id)

      room = Room.find(id)
      expect(room.name).to eq('Rush Fans')
      expect(data[:errors]).to be_blank
    end
  end

  context 'when missing required attributes' do
    it 'fails to persist when name is not specified' do
      expect do
        authed_post(
          url: '/api/v1/graphql',
          body: {
            query: query(name: nil)
          },
          user: current_user
        )
      end.not_to change(Room, :count)

      data = json_body.dig(:data, :roomCreate)

      expect(data[:room]).to be_nil
      expect(data[:errors]).to match_array([include("Name can't be blank")])
    end
  end
end
