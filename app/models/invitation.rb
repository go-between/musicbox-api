# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :inviting_user, foreign_key: :invited_by_id, class_name: 'User'
end
