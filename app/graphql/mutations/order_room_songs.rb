module Mutations
  class OrderRoomSongs < Mutations::BaseMutation
    argument :room_id, ID, required: true
    argument :song_ids, [ID], required: true

    field :errors, [String], null: true

    def resolve(room_id:, song_ids:)
      song_ids.each_with_index do |song_id, index|
        room_song = RoomSong.find_or_initialize_by(song_id: song_id, user: context[:current_user], room_id: room_id)
        room_song.order = index + 1
        room_song.save!
      end
      {
        errors: []
      }
    end
  end
end
