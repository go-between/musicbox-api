# frozen_string_literal: true

require 'rails_helper'
RSpec.describe BroadcastNowPlayingWorker, type: :worker do
  let(:played_at) { Time.zone.now }
  let(:song) { create(:song) }
  let(:room) { create(:room) }
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'broadcasts the current song and its start time' do
      record = create(:room_playlist_record, room: room, song: song, play_state: :played, played_at: played_at)
      room.update!(current_record: record)

      expect do
        worker.perform(room.id)
      end.to(have_broadcasted_to(room).from_channel(NowPlayingChannel).with do |msg|
        current_song_id = msg.dig(:data, :room, :currentSong, :id)
        expect(current_song_id).to eq(song.id)

        record_start = msg.dig(:data, :room, :currentRecord, :playedAt)
        expect(record_start).to eq(played_at.iso8601)
      end)
    end
  end
end
