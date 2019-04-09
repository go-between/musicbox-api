module Mutations
  class CreateRoomSong < Mutations::BaseMutation
    argument :order, Int, required: true
    argument :room_id, ID, required: true
    argument :song_id, ID, required: true

    field :room_song, Types::RoomSongType, null: true
    field :errors, [String], null: true

    def resolve(order:, room_id:, song_id:)
      room_song = RoomSong.new(order: order, room_id: room_id, song_id: song_id, user: context[:current_user])
      if room_song.save
        queue = MusicboxApiSchema.execute(query: query, variables: { roomId: room_song.room_id })
        QueuesChannel.broadcast_to(room_song.room, queue.to_h)
        # ActionCable.server.broadcast('now_playing', enqueued_songs(room_song).map(&:attributes))

        {
          room_song: room_song,
          errors: [],
        }
      else
        {
          room_song: nil,
          errors: room_song.errors.full_messages
        }
      end
    end

    private

    def query
      %(
        query($roomId: ID!) {
          RoomSongs(roomId: $roomId) {
            id, order, song { id, name }, user { email }
          }
        }
      )
    end
  end
end
