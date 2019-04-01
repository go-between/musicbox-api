class SongUser < ApplicationRecord
  self.table_name = "songs_users"
  belongs_to :song
  belongs_to :user
end
