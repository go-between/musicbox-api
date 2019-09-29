require 'rails_helper'
RSpec.describe BroadcastUsersWorker, type: :worker do
  let(:played_at) { Time.zone.now }
  let(:room) { create(:room) }
  let(:worker) { BroadcastUsersWorker.new }

  describe "#perform" do
    it "broadcasts a list of users in the room" do
      user1 = create(:user, room: room)
      user2 = create(:user, room: room)

      expect do
        worker.perform(room.id)
      end.to have_broadcasted_to(room).from_channel(UsersChannel).with { |msg|
        user_ids = msg.dig(:data, :room, :users).map { |u| u[:id] }

        expect(user_ids).to match_array([user1.id, user2.id])
      }
    end
  end
end