module Mutations
  class CreateSong < Mutations::BaseMutation
    argument :youtube_id, ID, required: true

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
        set_attrs_from_youtube!(song)
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

    private

    def set_attrs_from_youtube!(song)
      video = Yt::Video.new(id: song.youtube_id)
      song.update!(
        description: video.description,
        name: video.title,
        duration_in_seconds: video.duration
      )
    end
  end
end
