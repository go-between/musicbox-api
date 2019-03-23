# Define how to query and persist a given model.
# Further Resource documentation: https://jsonapi-suite.github.io/jsonapi_compliable/JsonapiCompliable/Resource.html
class RoomQueueResource < ApplicationResource
  # Used for associating this resource with a given input.
  # This should match the 'type' in the corresponding serializer.
  type :room_queues
  use_adapter JsonapiCompliable::Adapters::ActiveRecord
  # Associate to a Model object so we know how to persist.
  model RoomQueue

  belongs_to :room,
    scope: -> {Room.all},
    resource: RoomResource,
    foreign_key: :room_id

  belongs_to :song,
    scope: -> {Song.all},
    resource: SongResource,
    foreign_key: :song_id

  belongs_to :user,
    scope: -> {User.all},
    resource: UserResource,
    foreign_key: :user_id
end
