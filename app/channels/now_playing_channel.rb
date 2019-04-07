class NowPlayingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "now_playing_#{params[:room_id]}"
  end
end
