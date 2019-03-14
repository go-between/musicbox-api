class NowPlayingChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'now_playing'
  end
end
