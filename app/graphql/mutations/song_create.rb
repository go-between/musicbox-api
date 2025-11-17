# frozen_string_literal: true

module Mutations
  class SongCreate < Mutations::BaseMutation
    argument :youtube_id, ID, required: true
    argument :from_user_id, ID, required: false

    field :song, Types::SongType, null: true
    field :errors, [ String ], null: true

    def resolve(youtube_id:, from_user_id: nil)
      song = Song.find_or_initialize_by(youtube_id: youtube_id)

      unless song.valid?
        return {
          song: nil,
          errors: song.errors.full_messages
        }
      end

      attrs_from_youtube!(song) unless song.persisted?

      associate_song_to_user!(song, from_user_id)

      {
        song: song,
        errors: []
      }
    end

    private

    def associate_song_to_user!(song, from_user_id)
      record = LibraryRecord.find_or_initialize_by(song: song, user: context[:current_user])
      return if record.persisted?
      return record.save! if from_user_id.blank?

      record.update!(from_user_id: from_user_id, source: "saved_from_history")
    end

    def attrs_from_youtube!(song)
      video = YoutubeClient.new(current_user).find(song.youtube_id)
      song.update!(
        description: video.description,
        duration_in_seconds: video.duration,
        name: video.title,
        thumbnail_url: video.thumbnail_url,
        youtube_tags: video.tags,
        channel_title: video.channel_title,
        channel_id: video.channel_id,
        published_at: video.published_at,
        category_id: video.category_id
      )
    end
  end
end
