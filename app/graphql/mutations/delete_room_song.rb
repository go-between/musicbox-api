module Mutations
  class DeleteRoomSong < Mutations::BaseMutation
    argument :id, ID, required: true

    field :errors, [String], null: true

    def resolve(id:)
      room_song = RoomSong.find_by(id: id, user: context[:current_user])

      return {errors: ["Can't find song to delete"]} if room_song.blank?
      room_id = room_song.room_id
      room_song.destroy!
      BroadcastQueueWorker.perform_async(room_id)

      {
        errors: []
      }
    end
  end
end
