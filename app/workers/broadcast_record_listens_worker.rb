# frozen_string_literal: true

class BroadcastRecordListensWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_record_listens"

  def perform(record_id)
    room = Room.find_by(current_record_id: record_id)
    return if room.blank?

    listens = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { recordId: record_id }
    )
    RecordListensChannel.broadcast_to(room, listens.to_h)
  end

  private

  def query
    %(
      query BroadcastRecordListensWorker($recordId: ID!) {
        recordListens(recordId: $recordId) {
          id
          approval
          user {
            id
            email
            name
          }
        }
      }
    )
  end
end
