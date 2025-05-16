# frozen_string_literal: true

module Mutations
  class RoomPlaylistRecordDelete < Mutations::BaseMutation
    argument :id, ID, required: true

    field :errors, [ String ], null: true

    def resolve(id:)
      record = RoomPlaylistRecord.find_by(id: id, user: context[:current_user])
      return { errors: [ "Can't find song to delete" ] } if record.blank?

      room_id = record.room_id
      record.destroy!
      BroadcastPlaylistWorker.perform_async(room_id)

      {
        errors: []
      }
    end
  end
end
