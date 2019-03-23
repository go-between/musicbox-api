module Types
  class RoomType < Types::BaseObject
    graphql_name 'Room'

    field :id, ID, null: false
    field :name, String, null: false
  end
end
