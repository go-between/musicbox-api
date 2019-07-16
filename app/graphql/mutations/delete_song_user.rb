module Mutations
  class DeleteSongUser < Mutations::BaseMutation
    argument :song_id, ID, required: true

    field :errors, [String], null: true

    def resolve(song_id:)
      song_user = SongUser.find_by(song_id: song_id, user: context[:current_user])
      return {errors: ["Can't find song to delete"]} if song_user.blank?
      song_user.destroy!
      {
        errors: []
      }
    end
  end
end
