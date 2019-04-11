class NowPlayingChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "now_playing_#{params[:room_id]}"
    room = Room.find(params[:room_id])
    stream_for room
  end
end
