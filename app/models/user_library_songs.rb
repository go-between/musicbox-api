class UserLibrarySongs < ApplicationRecord
  belongs_to :song
  belongs_to :user
end
