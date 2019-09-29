# frozen_string_literal: true

class CreateJoinTableUserSong < ActiveRecord::Migration[5.2]
  def change
    create_join_table(:users, :songs, column_options: { type: :uuid }) do |t|
      t.index %i[user_id song_id]
      t.index %i[song_id user_id]
    end
  end
end
