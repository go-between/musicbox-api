# frozen_string_literal: true

class TeamUser < ApplicationRecord
  self.table_name = 'teams_users'
  belongs_to :user
  belongs_to :team
end
