# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Delete User Library Record", type: :request do
  include AuthHelper
  include JsonHelper

  def query(id:)
    %(
      mutation {
        deleteUserLibraryRecord(input:{
          id: "#{id}"
        }) {
          errors
        }
      }
    )
  end

  describe "success" do
    it "deletes a room playlist record belonging to the user" do
      record = create(:user_library_record, user: current_user)

      authed_post('/api/v1/graphql', query: query(id: record.id))
      data = json_body.dig(:data, :deleteUserLibraryRecord)

      expect(data[:errors]).to be_empty
      expect(UserLibraryRecord.find_by(id: record.id)).to_not be_present
    end
  end

  describe "error" do
    it "does not delete a playlist record belonging to another user" do
      record = create(:user_library_record, user: create(:user))

      authed_post('/api/v1/graphql', query: query(id: record.id))
      data = json_body.dig(:data, :deleteUserLibraryRecord)

      expect(data[:errors]).to_not be_empty
      expect(UserLibraryRecord.find_by(id: record.id)).to be_present
    end
  end
end