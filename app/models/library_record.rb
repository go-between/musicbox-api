# frozen_string_literal: true

class LibraryRecord < ApplicationRecord
  belongs_to :song
  belongs_to :user
  belongs_to :from_user, foreign_key: :from_user_id, class_name: "User", optional: true
  has_many :tag_library_records
  has_many :tags, through: :tag_library_records

  enum source: {
    saved_from_history: "saved_from_history",
    pending_recommendation: "pending_recommendation",
    accepted_recommendation: "accepted_recommendation"
  }
end
