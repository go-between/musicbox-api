# frozen_string_literal: true

require "rails_helper"

RSpec.describe Song, type: :model do
  let(:song) { described_class.create!(youtube_id: "abcd") }

  describe "relationships" do
    it "has many library records" do
      lib1 = create(:library_record, song: song)
      lib2 = create(:library_record, song: song)

      expect(song.reload.library_records).to contain_exactly(lib1, lib2)
    end

    it "has many users" do
      user1 = create(:user)
      user2 = create(:user)

      create(:library_record, song: song, user: user1)
      create(:library_record, song: song, user: user2)
      create(:library_record, song: song, user: user2)

      expect(song.reload.users).to contain_exactly(user1, user2, user2)
    end
  end

  it "has youtube tags" do
    song.update!(youtube_tags: %w[chill dope beatz])

    expect(song.youtube_tags).to match_array(%w[chill dope beatz])
  end

  describe ".search" do
    let!(:song1) do
      described_class.create!(
        youtube_id: "abc123",
        name: "Bohemian Rhapsody",
        channel_title: "Queen Official",
        description: "Official video for the iconic rock song",
        youtube_tags: %w[rock classic queen]
      )
    end

    let!(:song2) do
      described_class.create!(
        youtube_id: "def456",
        name: "Dancing Queen",
        channel_title: "ABBA",
        description: "Official music video for Dancing Queen by ABBA",
        youtube_tags: %w[disco pop abba]
      )
    end

    let!(:song3) do
      described_class.create!(
        youtube_id: "ghi789",
        name: "Billie Jean",
        channel_title: "Michael Jackson",
        description: "The king of pop's legendary performance",
        youtube_tags: %w[pop michael jackson]
      )
    end

    it "finds songs by name" do
      results = described_class.search("Bohemian")
      expect(results).to contain_exactly(song1)
    end

    it "finds songs by name prefix" do
      results = described_class.search("Boh")
      expect(results).to contain_exactly(song1)
    end

    it "finds songs by channel title" do
      results = described_class.search("Michael Jackson")
      expect(results).to contain_exactly(song3)
    end

    it "finds songs by description" do
      results = described_class.search("legendary performance")
      expect(results).to contain_exactly(song3)
    end

    it "finds songs by youtube tags" do
      results = described_class.search("disco")
      expect(results).to contain_exactly(song2)
    end

    it "finds multiple songs matching query" do
      results = described_class.search("queen")
      expect(results).to contain_exactly(song1, song2)
    end

    it "orders results by relevance" do
      # "Queen" appears in both name and channel_title for song1 (weight A)
      # "Queen" only appears in name for song2 (weight A)
      # song1 should rank higher due to appearing in more high-weight fields
      results = described_class.search("queen").to_a
      expect(results.first).to eq(song1)
    end

    it "returns empty array when no matches" do
      results = described_class.search("nonexistent")
      expect(results).to be_empty
    end

    it "handles nil gracefully" do
      results = described_class.search(nil)
      expect(results).to be_empty
    end

    it "falls back to fuzzy search for substring matching" do
      # Create songs where "loop" appears as substring in middle of words
      song4 = described_class.create!(
        youtube_id: "xyz123",
        name: "loopmaster supreme",
        channel_title: "Test Channel"
      )
      song5 = described_class.create!(
        youtube_id: "xyz124",
        name: "LOOPABLARG",
        channel_title: "Another Channel"
      )

      # "loop" should match via fuzzy trigram search (substring matching)
      results = described_class.search("loop")
      expect(results.map(&:id)).to include(song4.id, song5.id)
    end

    it "searches across name, channel_title, and youtube_tags with fuzzy matching" do
      # Song with query term in channel_title
      channel_match = described_class.create!(
        youtube_id: "ch1",
        name: "Some Song",
        channel_title: "Electronic Music Channel",
        youtube_tags: []
      )

      # Song with query term in tags
      tag_match = described_class.create!(
        youtube_id: "tg1",
        name: "Another Song",
        channel_title: "Random Channel",
        youtube_tags: [ "electronic", "beats" ]
      )

      results = described_class.search("electronic")
      expect(results.map(&:id)).to include(channel_match.id, tag_match.id)
    end
  end
end
