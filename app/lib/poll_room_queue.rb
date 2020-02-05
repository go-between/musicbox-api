# frozen_string_literal: true

class PollRoomQueue
  def initialize
    @room_arel = Room.arel_table
  end

  def poll!
    rooms_to_enqueue = recently_finished_playing.or(newly_enqueued)
    rooms_to_enqueue.each do |room|
      enqueue_for(room.id)
    end
  end

  private

  def newly_enqueued
    Room.where(playing_until: nil).where(waiting_songs: true)
  end

  def recently_finished_playing
    Room.where(@room_arel[:playing_until].lteq(Time.zone.now))
  end

  def enqueue_for(room_id)
    QueueManagementWorker.perform_async(room_id)
  end
end
