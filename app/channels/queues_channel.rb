class QueuesChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'queue'
  end
end
