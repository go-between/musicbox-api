module Types
  class SongType < Types::BaseObject
    graphql_name 'Song'

    field :id, ID, null: false
    field :duration_in_seconds, Int, null: true
    field :name, String, null: false
    field :youtube_id, String, null: false
  end
end
