module Types
  class OrderedRoomPlaylistRecord < Types::BaseInputObject
    argument :room_playlist_record_id, ID, required: false
    argument :song_id, ID, required: true
  end
end
