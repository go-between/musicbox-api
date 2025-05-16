class AddUniqueConstraintOnRecordListens < ActiveRecord::Migration[6.0]
  def up
    # You'd think I'd learn based on how awful the last data migration was.
    duplicates = RecordListen.group(:room_playlist_record_id, :song_id, :user_id)
                             .select(:room_playlist_record_id, :song_id, :user_id, "count(1) as total_count")
                             .having("count(1) > 1")
                             .to_a

    # Can't create a unique index while there are non-unique records in the database!
    duplicates.each do |d|
      all_duplicates = RecordListen.where(room_playlist_record_id: d.room_playlist_record_id, song_id: d.song_id, user_id: d.user_id)
      # Drop all but one, keeping the most recent.
      to_remove = all_duplicates.order(:created_at).limit(d.total_count - 1)
      to_remove.destroy_all
    end

    add_index :record_listens, [ :room_playlist_record_id, :song_id, :user_id ], unique: true, name: :unique_record_listens
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
