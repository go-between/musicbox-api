# frozen_string_literal: true

class Team < ApplicationRecord
  belongs_to :owner, foreign_key: :owner_id, class_name: 'User'
end
