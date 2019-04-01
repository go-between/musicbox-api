module Mutations
  class CreateSong < Mutations::BaseMutation
    argument :youtube_id, ID, required: true

    field :song, Types::SongType, null: true
    field :errors, [String], null: true

    def resolve(youtube_id:)
      song = Song.find_or_initialize_by(youtube_id: youtube_id)

      return {
        song: nil,
        errors: song.errors.full_messages,
      } unless song.valid?

      associate_song_to_user!(song)
      unless song.persisted?
        set_attrs_from_youtube!(song)
      end

      {
        song: song,
        errors: [],
      }
    end

    private

    def associate_song_to_user!(song)
      SongUser.find_or_create_by!(song: song, user: context[:current_user])
    end

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
