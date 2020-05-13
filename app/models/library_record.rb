# frozen_string_literal: true

class LibraryRecord < ApplicationRecord
  belongs_to :song
  belongs_to :user
  belongs_to :from_user, foreign_key: :from_user_id, class_name: "User", optional: true

  enum source: {
    saved_from_history: "saved_from_history",
    pending_recommendation: "pending_recommendation",
    accepted_recommendation: "accepted_recommendation"
  }
end
