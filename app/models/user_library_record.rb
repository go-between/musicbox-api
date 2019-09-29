# frozen_string_literal: true

class UserLibraryRecord < ApplicationRecord
  belongs_to :song
  belongs_to :user
end
