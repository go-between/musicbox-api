# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :inviting_user, foreign_key: :invited_by_id, class_name: 'User'

  def self.token
    SecureRandom.uuid
  end

  enum invitation_state: {
    pending: 'pending',
    accepted: 'accepted'
  }
end
