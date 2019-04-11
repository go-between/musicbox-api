require 'rails_helper'
RSpec.describe BroadcastNowPlayingWorker, type: :worker do
  let(:started) { Time.zone.now }
  let(:song) { create(:song) }
  let(:room) { create(:room, current_song: song, current_song_start: started) }
  let(:worker) { BroadcastNowPlayingWorker.new }

  describe "#perform" do
    it "broadcasts the current song and its start time" do
      expect do
        worker.perform(room.id)
      end.to have_broadcasted_to(room).from_channel(NowPlayingChannel).with { |msg|
        currentSongId = msg.dig(:data, :room, :currentSong, :id)
        expect(currentSongId).to eq(song.id)

        songStart = msg.dig(:data, :room, :currentSongStart)
        expect(songStart).to eq(started.iso8601)
      }
    end
  end
end
