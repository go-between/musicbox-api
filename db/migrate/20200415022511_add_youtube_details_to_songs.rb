class AddYoutubeDetailsToSongs < ActiveRecord::Migration[6.0]
  def change
    add_column :songs, :thumbnail_url, :string
    add_column :songs, :license, :string
    add_column :songs, :licensed, :boolean, default: false
    add_column :songs, :youtube_tags, :string, array: true, default: []
  end
end
