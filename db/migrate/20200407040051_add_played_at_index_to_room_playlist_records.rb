class AddPlayedAtIndexToRoomPlaylistRecords < ActiveRecord::Migration[6.0]
  def change
    add_index :room_playlist_records, :played_at
  end
end
