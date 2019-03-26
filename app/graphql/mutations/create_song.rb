module Mutations
  class CreateSong < Mutations::BaseMutation
    argument :youtube_id, String, required: true

    field :song, Types::SongType, null: true
    field :errors, [String], null: true

    def resolve(youtube_id:)
      persisted_song = Song.find_by(youtube_id: youtube_id)
      if persisted_song.present?
        return {
          song: persisted_song,
          errors: []
        }
      end

      song = Song.new(youtube_id: youtube_id)
      if song.save
        {
          song: song,
          errors: [],
        }
      else
        {
          song: nil,
          errors: song.errors.full_messages
        }
      end
    end
  end
end
