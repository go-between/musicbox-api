# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { described_class.create!(email: "test@test.com", password: "123456") }

  describe "relationships" do
    it "has many library records" do
      record1 = create(:library_record, user: user)
      record2 = create(:library_record, user: user)
      record3 = create(:library_record, user: user)

      expect(user.reload.library_records).to contain_exactly(record1, record2, record3)
    end

    it "has many songs" do
      song1 = create(:song)
      song2 = create(:song)

      create(:library_record, user: user, song: song1)
      create(:library_record, user: user, song: song2)
      create(:library_record, user: user, song: song2)

      expect(user.reload.songs).to contain_exactly(song1, song2, song2)
    end

    it "has many tags" do
      t1 = create(:tag, user: user)
      t2 = create(:tag, user: user)
      t3 = create(:tag, user: user)

      expect(user.tags).to contain_exactly(t1, t2, t3)
    end

    it "may belong to one active room" do
      room = create(:room)
      user.update!(active_room: room)

      expect(user.active_room).to eq(room)
    end

    it "may belong to one active team" do
      team = create(:team)
      user.update!(active_team: team)

      expect(user.active_team).to eq(team)
    end

    it "may be part of many teams" do
      team1 = create(:team)
      team2 = create(:team)

      user.teams << team1
      user.teams << team2

      expect(user.reload.teams).to contain_exactly(team1, team2)
    end
  end
end
