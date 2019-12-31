# frozen_string_literal: true

class Team < ApplicationRecord
  belongs_to :owner, foreign_key: :owner_id, class_name: 'User'
  has_many :team_users
  has_many :rooms
  has_many :users, through: :team_users
end
