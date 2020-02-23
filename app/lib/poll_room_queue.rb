# frozen_string_literal: true

class PollRoomQueue
  def initialize
    @room_arel = Room.arel_table
  end

  def poll!
    rooms = recently_finished_playing.or(newly_enqueued)
    # update_all will update directly in the database without instantiating
    # models, which is cool except that it also clears the relation
    # so we save it with #to_a first
    rooms_to_enqueue = rooms.to_a
    rooms.update_all(queue_processing: true) if rooms.any?

    rooms_to_enqueue.each do |room|
      enqueue_for(room.id)
    end
  end

  private

  def newly_enqueued
    Room.where(playing_until: nil, waiting_songs: true, queue_processing: false)
  end

  def recently_finished_playing
    Room.where(queue_processing: false).where(@room_arel[:playing_until].lteq(Time.zone.now))
  end

  def enqueue_for(room_id)
    QueueManagementWorker.perform_async(room_id)
  end
end
