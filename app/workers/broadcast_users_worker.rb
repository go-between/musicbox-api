# frozen_string_literal: true

class BroadcastUsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_users"

  def perform(room_id)
    queue = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { id: room_id }
    )
    UsersChannel.broadcast_to(Room.find(room_id), queue.to_h)
  end

  private

  def query
    %(
      query($id: ID!) {
        room(id: $id) {
          users {
            id
            name
            email
          }
        }
      }
    )
  end
end
