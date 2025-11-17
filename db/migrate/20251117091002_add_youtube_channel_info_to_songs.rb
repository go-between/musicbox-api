class AddYoutubeChannelInfoToSongs < ActiveRecord::Migration[6.0]
  def change
    add_column :songs, :channel_title, :string
    add_column :songs, :channel_id, :string
    add_column :songs, :published_at, :datetime
    add_column :songs, :category_id, :string

    add_index :songs, :channel_id
    add_index :songs, :published_at
  end
end
