module Types
  class OrderedSongObject < Types::BaseInputObject
    argument :room_song_id, ID, required: true
    argument :song_id, ID, required: true
  end
end
