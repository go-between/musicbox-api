# Serializers define the rendered JSON for a model instance.
# We use jsonapi-rb, which is similar to active_model_serializers.
class SerializableRoomQueue < JSONAPI::Serializable::Resource
  type :room_queues

  belongs_to :room
  belongs_to :song
  belongs_to :user
end
