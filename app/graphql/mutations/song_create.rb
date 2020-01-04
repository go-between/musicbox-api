# frozen_string_literal: true

module Mutations
  class SongCreate < Mutations::BaseMutation
    argument :youtube_id, ID, required: true

    field :song, Types::SongType, null: true
    field :errors, [String], null: true

    def resolve(youtube_id:)
      song = Song.find_or_initialize_by(youtube_id: youtube_id)

      unless song.valid?
        return {
          song: nil,
          errors: song.errors.full_messages
        }
      end

      attrs_from_youtube!(song) unless song.persisted?

      associate_song_to_user!(song)

      {
        song: song,
        errors: []
      }
    end

    private

    def associate_song_to_user!(song)
      UserLibraryRecord.find_or_create_by!(song: song, user: context[:current_user])
    end

    def attrs_from_youtube!(song)
      video = Yt::Video.new(id: song.youtube_id)
      song.update!(
        description: video.description,
        name: video.title,
        duration_in_seconds: video.duration
      )
    end
  end
end
