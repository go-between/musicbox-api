# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :validatable

  belongs_to :active_room, optional: true, foreign_key: :active_room_id, class_name: "Room"
  belongs_to :active_team, optional: true, foreign_key: :active_team_id, class_name: "Team"

  has_many :room_playlist_records
  has_many :user_library_records, lambda {
    # Excludes pending recommendations from user.songs retrievals
    # Note that we must add the "or" clause because Postgres will
    # exclude records where source is null with a not-equals comparison.
    where(
      arel_table[:source].not_eq("pending_recommendation")
      .or(arel_table[:source].eq(nil))
    )
  }, inverse_of: :user
  has_many :songs, through: :user_library_records
  has_many :tags
  has_many :team_users
  has_many :teams, through: :team_users

  def start_password_reset!
    # This is a protected method in Devise::Recoverable
    set_reset_password_token
  end
end
