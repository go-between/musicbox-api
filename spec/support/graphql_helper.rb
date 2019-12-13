# frozen_string_literal: true

module GraphQLHelper
  def join_room_mutation(room_id:)
    %(
      mutation {
        joinRoom(input:{
          roomId: "#{room_id}"
        }) {
          room {
            id
          }
          errors
        }
      }
    )
  end

  def order_room_playlist_records_mutation(room_id, records)
    input = records.map do |record|
      str = '{ '
      str += "songId: \"#{record[:song_id]}\""
      str += ", roomPlaylistRecordId: \"#{record[:room_playlist_record_id]}\""
      str + ' }'
    end

    %(
      mutation {
        orderRoomPlaylistRecords(input:{
          roomId: "#{room_id}",
          orderedRecords: [#{input.join(',')}]
        }) {
          errors
        }
      }
    )
  end
end
