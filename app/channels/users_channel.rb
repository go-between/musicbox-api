class UsersChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:room_id])
    stream_for room
  end

  def unsubscribed
    room_id = current_user.room_id
    current_user.update!(room: nil)
    BroadcastUsersWorker.perform_async(room_id)
  end
end
