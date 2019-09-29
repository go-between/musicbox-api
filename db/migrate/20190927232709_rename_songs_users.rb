# frozen_string_literal: true

class RenameSongsUsers < ActiveRecord::Migration[5.2]
  def change
    rename_table :songs_users, :user_library_songs
  end
end
