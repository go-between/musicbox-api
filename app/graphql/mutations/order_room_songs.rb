module Mutations
  class OrderRoomSongs < Mutations::BaseMutation
    argument :room_id, ID, required: true
    argument :ordered_songs, [Types::OrderedSongObject], required: true

    field :errors, [String], null: true

    def resolve(room_id:, ordered_songs:)
      room = Room.find(room_id)
      room.update!(user_rotation: room.user_rotation + [context[:current_user].id]) unless room.user_rotation.include?(context[:current_user].id)
      ordered_songs.each_with_index do |ordered_song, index|
        room_song = RoomSong.find_or_initialize_by(
                      id: ordered_song[:room_song_id],
                      room_id: room_id,
                      song_id: ordered_song[:song_id],
                      user: context[:current_user]
                    )
        room_song.update!(order: index + 1, play_state: "waiting")
      end

      BroadcastQueueWorker.perform_async(room_id)
      {
        errors: []
      }
    end
  end
end
