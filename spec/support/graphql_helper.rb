# frozen_string_literal: true

module GraphQLHelper
  def room_activate_mutation(room_id:)
    %(
      mutation {
        roomActivate(input:{
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

  def room_playlist_query(room_id:)
    %(
      query {
        roomPlaylist(roomId: "#{room_id}") {
          id
          song {
            id
          }
          user{
            id
          }
        }
      }
    )
  end
end
