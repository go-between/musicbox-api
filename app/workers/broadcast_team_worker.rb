# frozen_string_literal: true

class BroadcastTeamWorker
  include Sidekiq::Worker
  sidekiq_options queue: "broadcast_team"

  def perform(team_id)
    queue = MusicboxApiSchema.execute(
      query: query,
      context: { override_current_user: true },
      variables: { id: team_id }
    )
    TeamChannel.broadcast_to(Team.find(team_id), queue.to_h)
  end

  private

  def query
    %(
      query BroadcastTeamWorker($id: ID!) {
        team(id: $id) {
          rooms {
            id
            name
            currentSong {
              name
            }
          }
        }
      }
    )
  end
end
