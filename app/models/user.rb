# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :room, optional: true, foreign_key: :active_room_id
  has_many :user_library_records
  has_many :songs, through: :user_library_records
  has_many :team_users
  has_many :teams, through: :team_users
end
