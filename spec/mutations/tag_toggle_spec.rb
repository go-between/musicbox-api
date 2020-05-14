# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tag Add", type: :request do
  include AuthHelper
  include JsonHelper

  def query
    %(
      mutation TagToggle($tagId: ID!, $addIds: [ID!]!, $removeIds: [ID!]!) {
        tagToggle(input:{
          tagId: $tagId,
          addIds: $addIds,
          removeIds: $removeIds
        }) {
          errors
        }
      }
    )
  end

  let(:current_user) { create(:user, active_team: create(:team)) }
  let(:tag) { create(:tag, user: current_user) }
  let(:library_record1) { create(:library_record, user: current_user) }
  let(:library_record2) { create(:library_record, user: current_user) }
  let(:library_record3) { create(:library_record, user: current_user) }
  let(:library_record4) { create(:library_record, user: current_user) }

  describe "adding an association" do
    it "adds tag and removes tag from songs" do
      TagLibraryRecord.create(tag_id: tag.id, library_record_id: library_record1.id)
      TagLibraryRecord.create(tag_id: tag.id, library_record_id: library_record2.id)

      graphql_request(
        query: query,
        variables: {
          tagId: tag.id,
          addIds: [library_record1.id, library_record3.id],
          removeIds: [library_record2.id, library_record4.id]
        },
        user: current_user
      )

      expect(library_record1.tags).to include(tag)
      expect(library_record2.tags).not_to include(tag)
      expect(library_record3.tags).to include(tag)
      expect(library_record4.tags).not_to include(tag)
    end
  end

  context "when tag is misconfigured" do
    it "returns an error when tag does not exist" do
      expect do
        graphql_request(
          query: query,
          variables: { tagId: SecureRandom.uuid, addIds: [library_record1.id], removeIds: [library_record2.id] },
          user: current_user
        )
      end.not_to change(TagLibraryRecord, :count)

      expect(json_body.dig(:data, :tagToggle, :tag)).to be_nil
      expect(json_body.dig(:data, :tagToggle, :errors)).to include("Tag must be present")
    end

    it "returns an error when tag is not associated with the user" do
      other_tag = create(:tag, user: create(:user))
      expect do
        graphql_request(
          query: query,
          variables: { tagId: other_tag.id, addIds: [library_record1.id], removeIds: [library_record2.id] },
          user: current_user
        )
      end.not_to change(TagLibraryRecord, :count)

      expect(json_body.dig(:data, :tagToggle, :tag)).to be_nil
      expect(json_body.dig(:data, :tagToggle, :errors)).to include("Tag must be present")
    end
  end
end
