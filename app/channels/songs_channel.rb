class SongsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'songs'
  end
end
